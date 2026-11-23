"""Measure the owned child process on Windows; stdout/stderr stay in its run log."""
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import subprocess
import sys
import time

class Memory(ctypes.Structure):
    _fields_ = [('cb', wintypes.DWORD), ('PageFaultCount', wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in (
            'PeakWorkingSetSize', 'WorkingSetSize', 'QuotaPeakPagedPoolUsage',
            'QuotaPagedPoolUsage', 'QuotaPeakNonPagedPoolUsage', 'QuotaNonPagedPoolUsage',
            'PagefileUsage', 'PeakPagefileUsage', 'PrivateUsage')]

get_memory = ctypes.windll.psapi.GetProcessMemoryInfo
get_memory.argtypes = [wintypes.HANDLE, ctypes.POINTER(Memory), wintypes.DWORD]
get_memory.restype = wintypes.BOOL
get_times = ctypes.windll.kernel32.GetProcessTimes
get_times.argtypes = [wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4
get_times.restype = wintypes.BOOL
get_affinity = ctypes.windll.kernel32.GetProcessAffinityMask
get_affinity.argtypes = [wintypes.HANDLE, ctypes.POINTER(ctypes.c_size_t), ctypes.POINTER(ctypes.c_size_t)]
get_affinity.restype = wintypes.BOOL
report = Path(sys.argv[1])
if report.exists():
    raise SystemExit(f'Preserve the existing resource report: {report}')
command = sys.argv[2:]
started = time.perf_counter()
process = subprocess.Popen(command, stdout=sys.stdout, stderr=sys.stderr,
                           creationflags=subprocess.CREATE_NO_WINDOW)
peak = private_peak = samples = 0
affinity = ctypes.c_size_t()
system_affinity = ctypes.c_size_t()
get_affinity(int(process._handle), ctypes.byref(affinity), ctypes.byref(system_affinity))
while True:
    memory = Memory()
    memory.cb = ctypes.sizeof(memory)
    if get_memory(int(process._handle), ctypes.byref(memory), memory.cb):
        peak = max(peak, memory.PeakWorkingSetSize)
        private_peak = max(private_peak, memory.PrivateUsage)
        samples += 1
    if process.poll() is not None:
        break
    time.sleep(.1)
creation, exit_time, kernel, user = (wintypes.FILETIME() for _ in range(4))
valid_times = get_times(int(process._handle), ctypes.byref(creation), ctypes.byref(exit_time),
                        ctypes.byref(kernel), ctypes.byref(user))
def seconds(value):
    return ((value.dwHighDateTime << 32) | value.dwLowDateTime) / 1e7
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(json.dumps(dict(exit_code=process.returncode, elapsed_seconds=time.perf_counter()-started,
    peak_working_set_bytes=peak, sampled_peak_private_bytes=private_peak, memory_samples=samples,
    user_cpu_seconds=seconds(user) if valid_times else None,
    kernel_cpu_seconds=seconds(kernel) if valid_times else None, affinity_mask=affinity.value,
    scope='Entire R process: loading, input preparation, fitting, saved outputs and prediction.'), indent=2))
sys.exit(process.returncode)
