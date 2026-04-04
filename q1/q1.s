# q1.s  –  Binary Search Tree  (x86-64 Linux, AT&T syntax)
#
# struct Node { int val; struct Node* left; struct Node* right; }
# Memory layout (24 bytes):
#   offset  0 : val   (4 bytes, int)
#   offset  8 : left  (8 bytes, pointer)
#   offset 16 : right (8 bytes, pointer)
#
# Calling convention (System V AMD64 ABI):
#   args : rdi, rsi, rdx, rcx, r8, r9
#   return: rax
#   callee-saved: rbx, rbp, r12-r15

    .text

# ===================================================================
# struct Node* make_node(int val)
#   rdi = val (int)
#   returns: rax = pointer to new node
# ===================================================================
    .globl make_node
make_node:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx

    movl    %edi, %ebx          # save val (low 32 bits of rdi)

    movl    $24,  %edi          # malloc(24)
    call    malloc

    movl    %ebx, 0(%rax)       # node->val   = val
    movq    $0,   8(%rax)       # node->left  = NULL
    movq    $0,  16(%rax)       # node->right = NULL

    popq    %rbx
    popq    %rbp
    ret

# ===================================================================
# struct Node* insert(struct Node* root, int val)
#   rdi = root, esi = val
#   returns: rax = root (possibly newly created if root was NULL)
# ===================================================================
    .globl insert
insert:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12

    movq    %rdi, %rbx          # rbx = root
    movl    %esi, %r12d         # r12d = val

    # if root == NULL: create new node and return it
    testq   %rbx, %rbx
    jnz     .Linsert_notnull

    movl    %r12d, %edi
    call    make_node           # rax = new node
    jmp     .Linsert_ret

.Linsert_notnull:
    movl    0(%rbx), %eax       # eax = root->val
    cmpl    %r12d, %eax
    je      .Linsert_dup        # equal: no duplicate, return root
    jg      .Linsert_left       # root->val > val: go left

    # go right
    movq    16(%rbx), %rdi
    movl    %r12d, %esi
    call    insert
    movq    %rax, 16(%rbx)      # root->right = result
    movq    %rbx, %rax
    jmp     .Linsert_ret

.Linsert_left:
    movq    8(%rbx), %rdi
    movl    %r12d, %esi
    call    insert
    movq    %rax, 8(%rbx)       # root->left = result

.Linsert_dup:
    movq    %rbx, %rax          # return original root

.Linsert_ret:
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# ===================================================================
# struct Node* get(struct Node* root, int val)
#   rdi = root, esi = val
#   returns: rax = pointer to matching node, or NULL
# ===================================================================
    .globl get
get:
    pushq   %rbp
    movq    %rsp, %rbp

    # if root == NULL, return NULL
    testq   %rdi, %rdi
    jz      .Lget_null

    movl    0(%rdi), %eax       # eax = root->val
    cmpl    %esi, %eax
    je      .Lget_found
    jg      .Lget_left

    # go right
    movq    16(%rdi), %rdi
    call    get
    jmp     .Lget_ret

.Lget_left:
    movq    8(%rdi), %rdi
    call    get
    jmp     .Lget_ret

.Lget_found:
    movq    %rdi, %rax
    jmp     .Lget_ret

.Lget_null:
    xorq    %rax, %rax

.Lget_ret:
    popq    %rbp
    ret

# ===================================================================
# int getAtMost(int val, struct Node* root)
#   edi = val (target), rsi = root
#   returns: eax = greatest value in tree that is <= val, or -1
#
# Iterative BST floor search.
# ===================================================================
    .globl getAtMost
getAtMost:
    pushq   %rbp
    movq    %rsp, %rbp

    movl    %edi, %ecx          # ecx = target val
    movq    %rsi, %rdx          # rdx = current node
    movl    $-1,  %eax          # best = -1

.LgetAtMost_loop:
    testq   %rdx, %rdx
    jz      .LgetAtMost_done    # node == NULL: done

    movl    0(%rdx), %esi       # esi = node->val
    cmpl    %ecx, %esi
    jg      .LgetAtMost_go_left # node->val > target: go left

    # node->val <= target: candidate
    cmpl    %eax, %esi
    jle     .LgetAtMost_go_right
    movl    %esi, %eax          # update best

.LgetAtMost_go_right:
    movq    16(%rdx), %rdx      # go right (seek larger values still <= val)
    jmp     .LgetAtMost_loop

.LgetAtMost_go_left:
    movq    8(%rdx), %rdx
    jmp     .LgetAtMost_loop

.LgetAtMost_done:
    popq    %rbp
    ret
    
