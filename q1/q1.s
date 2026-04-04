# q1.s  -  Binary Search Tree  (RISC-V 64, Linux, GNU assembler)
#
# struct Node { int val; struct Node* left; struct Node* right; }
# Memory layout (24 bytes, 8-byte aligned):
#   offset  0 : val   (4 bytes, int)
#   offset  8 : left  (8 bytes, pointer)
#   offset 16 : right (8 bytes, pointer)
#
# RISC-V calling convention (LP64):
#   args     : a0-a7
#   return   : a0
#   callee-saved : s0-s11, sp, ra (must preserve across calls)
#   caller-saved : a0-a7, t0-t6   (scratch, can clobber)

    .text

# ===================================================================
# struct Node* make_node(int val)
#   a0 = val (int)
#   returns a0 = pointer to new zeroed node
# ===================================================================
    .globl make_node
make_node:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)

    mv      s0, a0              # s0 = val (save across malloc call)

    li      a0, 24              # malloc(24)
    call    malloc

    sw      s0, 0(a0)           # node->val   = val  (int, 4 bytes)
    sd      zero, 8(a0)         # node->left  = NULL
    sd      zero, 16(a0)        # node->right = NULL
    # a0 already = new node ptr

    ld      s0, 0(sp)
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

# ===================================================================
# struct Node* insert(struct Node* root, int val)
#   a0 = root, a1 = val
#   returns a0 = root (new node if root was NULL)
# ===================================================================
    .globl insert
insert:
    addi    sp, sp, -32
    sd      ra,  24(sp)
    sd      s0,  16(sp)         # s0 = root
    sd      s1,   8(sp)         # s1 = val

    mv      s0, a0
    mv      s1, a1

    # if root == NULL: make_node(val) and return
    bnez    s0, insert_notnull

    mv      a0, s1
    call    make_node           # a0 = new node
    j       insert_ret

insert_notnull:
    lw      t0, 0(s0)           # t0 = root->val
    beq     t0, s1, insert_dup  # equal → duplicate, return root

    bgt     t0, s1, insert_left # root->val > val → go left

    # go right
    ld      a0, 16(s0)          # a0 = root->right
    mv      a1, s1
    call    insert
    sd      a0, 16(s0)          # root->right = result
    mv      a0, s0
    j       insert_ret

insert_left:
    ld      a0, 8(s0)           # a0 = root->left
    mv      a1, s1
    call    insert
    sd      a0, 8(s0)           # root->left = result

insert_dup:
    mv      a0, s0              # return original root

insert_ret:
    ld      s1,  8(sp)
    ld      s0,  16(sp)
    ld      ra,  24(sp)
    addi    sp, sp, 32
    ret

# ===================================================================
# struct Node* get(struct Node* root, int val)
#   a0 = root, a1 = val
#   returns a0 = pointer to node, or NULL
# ===================================================================
    .globl get
get:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)

    # if root == NULL, return NULL (a0 already 0)
    beqz    a0, get_ret

    lw      t0, 0(a0)           # t0 = root->val
    beq     t0, a1, get_found
    bgt     t0, a1, get_left

    # go right
    ld      a0, 16(a0)
    call    get
    j       get_ret

get_left:
    ld      a0, 8(a0)
    call    get
    j       get_ret

get_found:
    # a0 already = root ptr

get_ret:
    ld      s0, 0(sp)
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

# ===================================================================
# int getAtMost(int val, struct Node* root)
#   a0 = val (target), a1 = root
#   returns a0 = greatest value in tree <= val, or -1
#
# Iterative floor search — no stack frames needed beyond the prologue.
# ===================================================================
    .globl getAtMost
getAtMost:
    # pure iterative, no calls → no need to save ra
    mv      t0, a0              # t0 = target
    mv      t1, a1              # t1 = current node
    li      t2, -1              # t2 = best answer

getAtMost_loop:
    beqz    t1, getAtMost_done  # node == NULL → done

    lw      t3, 0(t1)           # t3 = node->val
    bgt     t3, t0, getAtMost_left  # node->val > target → go left

    # node->val <= target: candidate
    bge     t2, t3, getAtMost_right  # not better than best
    mv      t2, t3              # update best

getAtMost_right:
    ld      t1, 16(t1)          # go right
    j       getAtMost_loop

getAtMost_left:
    ld      t1, 8(t1)           # go left
    j       getAtMost_loop

getAtMost_done:
    mv      a0, t2
    ret
    