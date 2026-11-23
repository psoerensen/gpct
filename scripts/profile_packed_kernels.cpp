// Diagnostic harness only. Calls the installed gbayes/gbits kernels; no sampler.
// [[Rcpp::plugins(cpp17)]]
#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#endif
#include <Rcpp.h>
#include <R_ext/BLAS.h>
#include <gbayes/individual_bed.hpp>
#include <gbits/bed_reader.hpp>
#include <gbits/prepared_matrix.hpp>
#include <chrono>
#include <algorithm>
#include <memory>
#include <limits>
#include <numeric>

using Clock = std::chrono::steady_clock;
double thread_seconds() {
#ifdef _WIN32
  FILETIME creation,exit,kernel,user;
  if(GetThreadTimes(GetCurrentThread(),&creation,&exit,&kernel,&user)) {
    const auto ticks=[](FILETIME f){return (static_cast<std::uint64_t>(f.dwHighDateTime)<<32)|f.dwLowDateTime;};
    return static_cast<double>(ticks(kernel)+ticks(user))*1e-7;
  }
#endif
  return 0;
}
double thread_cycles() {
#ifdef _WIN32
  ULONG64 cycles=0;if(QueryThreadCycleTime(GetCurrentThread(),&cycles)) return static_cast<double>(cycles);
#endif
  return 0;
}
// Existing gbits SIMD source is compiled unchanged into this diagnostic DLL.
namespace gbits::detail {
void avx2_axpy(double*,const double*,double,std::size_t) noexcept;
double avx2_dot(const double*,const double*,std::size_t) noexcept;
}
// [[Rcpp::export]]
Rcpp::List packed_probe_capabilities() {
  return Rcpp::List::create(Rcpp::Named("installed_gbits_avx2_compiled")=gbits::avx2_compiled(),
    Rcpp::Named("cpu_os_avx2_supported")=gbits::avx2_supported());
}
struct PackedProbe {
  gbayes::IndividualBedStatistics native;
  std::unique_ptr<gbits::PreparedBitMatrix> packed;
  std::vector<double> maps,diagonal,base,old,delta;
  std::vector<double> cache;
  std::vector<std::size_t> order;
  double view_seconds{};
  bool reordered{};
  std::size_t n{},p{};
};

// [[Rcpp::export]]
SEXP packed_probe_create(Rcpp::List configuration) {
  gbayes::IndividualBedInput input;
  input.physical_sample_count=Rcpp::as<double>(configuration["physical_n"]);
  for(double x:Rcpp::as<std::vector<double>>(configuration["samples"]))
    input.sample_indices.push_back(static_cast<std::uint64_t>(x));
  gbayes::IndividualBedFile file;
  file.path=Rcpp::as<std::string>(configuration["bed"]);
  file.physical_marker_count=Rcpp::as<double>(configuration["physical_p"]);
  for(double x:Rcpp::as<std::vector<double>>(configuration["markers"]))
    file.marker_indices.push_back(static_cast<std::uint64_t>(x));
  input.files.push_back(file);
  input.marker_ids=Rcpp::as<std::vector<std::string>>(configuration["marker_ids"]);
  input.phenotype=Rcpp::as<std::vector<double>>(configuration["phenotype"]);
  input.allele_frequency=Rcpp::as<std::vector<double>>(configuration["frequency"]);
  input.standardize=true;input.trait="profiling_only";
  auto probe=std::make_unique<PackedProbe>();
  probe->native=gbayes::prepare_individual_bed(input); // installed binary
  probe->n=probe->native.sample_count;probe->p=input.marker_ids.size();
  if(configuration.containsElementNamed("order")) {
    for(double value:Rcpp::as<std::vector<double>>(configuration["order"]))
      probe->order.push_back(static_cast<std::size_t>(value));
  } else {probe->order.resize(probe->p);std::iota(probe->order.begin(),probe->order.end(),0);}
  auto sorted=probe->order;std::sort(sorted.begin(),sorted.end());
  if(sorted.size()!=probe->p) Rcpp::stop("Marker order extent differs");
  for(std::size_t j=0;j<probe->p;++j) {
    if(sorted[j]!=j) Rcpp::stop("Marker order must be a permutation");
    if(probe->order[j]!=j) probe->reordered=true;
  }
  if(probe->n>static_cast<std::size_t>(std::numeric_limits<int>::max()))
    Rcpp::stop("BLAS vector dimension exceeds int range");
  gbits::BedReader reader(file.path,input.physical_sample_count,file.physical_marker_count);
  std::vector<std::uint64_t> ordered_markers;
  for(auto j:probe->order) ordered_markers.push_back(file.marker_indices[j]);
  auto view_start=Clock::now();
  auto selection=reader.make_selection(input.sample_indices.data(),input.sample_indices.size(),
    ordered_markers.data(),ordered_markers.size());
  probe->packed=std::make_unique<gbits::PreparedBitMatrix>(reader.prepare(selection));
  probe->view_seconds=std::chrono::duration<double>(Clock::now()-view_start).count();
  auto coding=gbayes::individual_bed_coding(probe->native.statistics);
  for(std::size_t j=0;j<probe->p;++j) {
    probe->diagonal.push_back(probe->native.statistics.cross_products->diagonal(j));
  }
  for(auto j:probe->order) {
    double center=coding.centers[j],scale=coding.scales[j];
    probe->maps.insert(probe->maps.end(),{-center/scale,(1-center)/scale,(2-center)/scale,0});
  }
  probe->base=Rcpp::as<std::vector<double>>(configuration["residual"]);
  probe->old=Rcpp::as<std::vector<double>>(configuration["effects"]);
  probe->delta=Rcpp::as<std::vector<double>>(configuration["delta"]);
  if(probe->base.size()!=probe->n||probe->old.size()!=probe->p||probe->delta.size()!=probe->p)
    Rcpp::stop("Replay dimensions differ");
  return Rcpp::XPtr<PackedProbe>(probe.release(),true);
}

// Optional immutable cache, capped independently of fitting controls.
// [[Rcpp::export]]
Rcpp::List packed_probe_enable_cache(SEXP pointer,double requested_bytes=2147483648.0) {
  Rcpp::XPtr<PackedProbe> x(pointer);
  double available=0;
#ifdef _WIN32
  MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
  if(GlobalMemoryStatusEx(&memory)) available=static_cast<double>(memory.ullAvailPhys);
#endif
  const double required=static_cast<double>(x->n)*static_cast<double>(x->p)*sizeof(double);
  const double budget=std::min(requested_bytes,available*.2);
  if(required>budget||!available) return Rcpp::List::create(Rcpp::Named("allocated")=false,
    Rcpp::Named("available_bytes")=available,Rcpp::Named("budget_bytes")=budget,
    Rcpp::Named("required_bytes")=required,Rcpp::Named("seconds")=0);
  auto start=Clock::now();
  x->cache.resize(x->n*x->p);
  std::vector<double> buffer(x->n*64);
  for(std::size_t first=0;first<x->p;first+=64) {
    const auto count=std::min(std::size_t{64},x->p-first);
    x->packed->decode_mapped_columns(x->maps,first,count,buffer.data(),buffer.size(),x->n,1);
    for(std::size_t k=0;k<count;++k)
      std::copy_n(buffer.data()+k*x->n,x->n,x->cache.data()+x->order[first+k]*x->n);
  }
  return Rcpp::List::create(Rcpp::Named("allocated")=true,
    Rcpp::Named("available_bytes")=available,Rcpp::Named("budget_bytes")=budget,
    Rcpp::Named("required_bytes")=required,
    Rcpp::Named("seconds")=std::chrono::duration<double>(Clock::now()-start).count());
}

// Replay identical, predetermined score/update events. No RNG or variance fit.
// [[Rcpp::export]]
Rcpp::List packed_probe_run(SEXP pointer,std::string kernel,std::string phase,int repeats=3) {
  Rcpp::XPtr<PackedProbe> x(pointer);
  const bool current=kernel=="current";
  const bool cached=kernel=="cached_blas";
  const bool avx=kernel.size()>5&&kernel.substr(kernel.size()-5)=="_avx2";
  std::size_t width=1;
  if(cached&&x->cache.size()!=x->n*x->p) Rcpp::stop("Decoded cache is not allocated");
  if(!current&&!cached) {
    if(kernel.rfind("decode",0)!=0||(!avx&&kernel.substr(kernel.size()-5)!="_blas"))
      Rcpp::stop("Invalid kernel");
    width=std::stoul(kernel.substr(6,kernel.find('_')-6));
    if(!width||width>256||(avx&&!gbits::avx2_supported())) Rcpp::stop("Unsupported kernel");
  }
  if(repeats<1||
    (phase!="score"&&phase!="update"&&phase!="joint"&&phase!="decode")) Rcpp::stop("Invalid replay");
  if(current&&phase=="decode") Rcpp::stop("Current dot/update kernels fuse decoding");
  if(width>1&&phase=="update") Rcpp::stop("Use sparse one-column update replay");
  const int n=static_cast<int>(x->n),inc=1;
  std::vector<double> scores(x->p),e,buffer(x->n*width);
  auto residual=x->native.statistics.cross_products->make_residual(x->native.statistics.score);
  double seconds=0,cpu_seconds=0,cycles=0;
  const bool score=phase=="score"||phase=="joint";
  const bool update=phase=="update"||phase=="joint";
  for(int repeat=0;repeat<repeats;++repeat) {
    e=x->base;residual->restore_working_state(x->base);
    auto start=Clock::now();
    auto cpu_start=thread_seconds(),cycle_start=thread_cycles();
    if(current) {
      for(auto j:x->order) {
        if(score) scores[j]=residual->conditional_score(j,x->old[j]);
        if(update&&x->delta[j]!=0) residual->update(j,x->delta[j]);
      }
    } else if(cached) {
      for(auto j:x->order) {
        const double* column=x->cache.data()+j*x->n;
        if(score) scores[j]=F77_CALL(ddot)(&n,column,&inc,e.data(),&inc)+x->diagonal[j]*x->old[j];
        if(update&&x->delta[j]!=0) {
          const double scale=-x->delta[j];F77_CALL(daxpy)(&n,&scale,column,&inc,e.data(),&inc);
        }
      }
    } else {
      for(std::size_t first=0;first<x->p;first+=width) {
        if(phase=="update"&&x->delta[x->order[first]]==0) continue;
        const auto count=std::min(width,x->p-first);
        x->packed->decode_mapped_columns(x->maps,first,count,buffer.data(),buffer.size(),x->n,1);
        for(std::size_t k=0;k<count;++k) {
          const auto j=x->order[first+k];double* column=buffer.data()+k*x->n;
          if(score) scores[j]=(avx ? gbits::detail::avx2_dot(column,e.data(),x->n) :
            F77_CALL(ddot)(&n,column,&inc,e.data(),&inc))+x->diagonal[j]*x->old[j];
          if(update&&x->delta[j]!=0) {
            const double scale=-x->delta[j];
            if(avx) gbits::detail::avx2_axpy(e.data(),column,scale,x->n);
            else F77_CALL(daxpy)(&n,&scale,column,&inc,e.data(),&inc);
          }
          if(phase=="decode") scores[j]=column[0];
        }
      }
    }
    seconds+=std::chrono::duration<double>(Clock::now()-start).count();
    cpu_seconds+=thread_seconds()-cpu_start;cycles+=thread_cycles()-cycle_start;
  }
  if(current) e=residual->working_state();
  return Rcpp::List::create(Rcpp::Named("seconds")=seconds/repeats,
    Rcpp::Named("cpu_seconds")=cpu_seconds/repeats,Rcpp::Named("cycles")=cycles/repeats,
    Rcpp::Named("scores")=scores,Rcpp::Named("residual")=e,
    Rcpp::Named("markers")=x->p,Rcpp::Named("samples")=x->n,
    Rcpp::Named("packed_bytes")=x->native.packed_memory_bytes,
    Rcpp::Named("candidate_view_seconds")=x->view_seconds,
    Rcpp::Named("candidate_view_packed_bytes")=x->native.packed_memory_bytes,
    Rcpp::Named("reordered_packed_view")=x->reordered,
    Rcpp::Named("decoded_cache_bytes")=x->cache.size()*sizeof(double),
    Rcpp::Named("updates")=std::count_if(x->delta.begin(),x->delta.end(),[](double v){return v!=0;}),
    Rcpp::Named("scratch_bytes")=current?0:buffer.size()*sizeof(double));
}
