/* Environment inspection only: no statistical computation. */
#include <R.h>
#include <Rinternals.h>
#ifdef _WIN32
#include <windows.h>
SEXP gpct_blas_info(void) {
    HMODULE module = GetModuleHandleA("Rblas.dll");
    if (!module) error("Rblas.dll is not loaded");
    typedef char *(*text_fn)(void);
    typedef int (*int_fn)(void);
    text_fn config = (text_fn)GetProcAddress(module, "openblas_get_config");
    text_fn core = (text_fn)GetProcAddress(module, "openblas_get_corename");
    int_fn threads = (int_fn)GetProcAddress(module, "openblas_get_num_threads");
    if (!config || !threads) error("Loaded Rblas.dll does not expose OpenBLAS inspection functions");
    char path[32768];
    if (!GetModuleFileNameA(module, path, sizeof(path))) error("Cannot identify loaded BLAS module");
    SEXP answer = PROTECT(allocVector(VECSXP, 4));
    SEXP names = PROTECT(allocVector(STRSXP, 4));
    const char *fields[] = {"implementation", "core", "threads", "library_path"};
    for (int i=0; i<4; ++i) SET_STRING_ELT(names, i, mkChar(fields[i]));
    SET_VECTOR_ELT(answer, 0, mkString(config()));
    SET_VECTOR_ELT(answer, 1, mkString(core ? core() : "unavailable"));
    SET_VECTOR_ELT(answer, 2, ScalarInteger(threads()));
    SET_VECTOR_ELT(answer, 3, mkString(path));
    setAttrib(answer, R_NamesSymbol, names);
    UNPROTECT(2);
    return answer;
}
#else
SEXP gpct_blas_info(void) { error("This probe targets the pinned Windows environment"); return R_NilValue; }
#endif
