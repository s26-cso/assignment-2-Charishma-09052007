/* q4.c – ISS-6701 Calculator
 *
 * Reads lines of the form:  <op> <num1> <num2>
 * Dynamically loads ./lib<op>.so at runtime, calls op(num1, num2),
 * prints the result, then UNLOADS the library immediately to stay
 * well under the 2 GB memory limit (each .so can be up to 1.5 GB).
 *
 * Compile:  gcc -o calc q4.c -ldl
 */

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <stdint.h>
 #include <dlfcn.h>
 
 /* op name is at most 5 chars; path is "lib" + 5 + ".so" + NUL = 12 chars */
 #define OP_MAX   5
 #define PATH_MAX_LEN 16   /* "./lib" + 5 + ".so\0" = 14, round up */
 
 int main(void)
 {
     char op[OP_MAX + 1];
     int  num1, num2;
 
     while (scanf("%5s %d %d", op, &num1, &num2) == 3) {
 
         /* Build the shared-library path: ./lib<op>.so */
         char path[PATH_MAX_LEN];
         snprintf(path, sizeof(path), "./lib%s.so", op);
 
         /* Load the library (RTLD_NOW: resolve all symbols immediately) */
         void *handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
         if (!handle) {
             fprintf(stderr, "dlopen failed for %s: %s\n", path, dlerror());
             return 1;
         }
 
         /* Clear any previous dlerror */
         dlerror();
 
         /* Look up the function symbol */
         typedef int (*op_fn)(int, int);
         op_fn fn = (op_fn)(intptr_t)dlsym(handle, op);
         const char *err = dlerror();
         if (err) {
             fprintf(stderr, "dlsym failed for '%s': %s\n", op, err);
             dlclose(handle);
             return 1;
         }
 
         /* Call the operation and print the result */
         int result = fn(num1, num2);
         printf("%d\n", result);
         fflush(stdout);
 
         /* Unload the library immediately – frees up to 1.5 GB per op */
         dlclose(handle);
     }
 
     return 0;
 }