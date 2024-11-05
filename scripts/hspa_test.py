import random
import math
import os

# polynomial: [x(n-1), x(n-2), ..., x1, x0]

# generate a polynomial(list) of length n with random values of 0 or 1
def poly_gen_dense(n):
    return [random.randint(0, 1) for _ in range(n)]

# generate w unique random indices(integers) within the range [0, n) and returns them in sorted order
def idx_gen(n, w):
    if w > n:
        raise ValueError("w cannot be greater than n")
    return sorted(random.sample(range(n), w))

# circular shift the input polynomial by delta bits directly
def cir_shift(x, delta):
    return x[delta:] + x[:delta]

# perform the XOR operation between two polynomials
def xor_bitwise(x, y):
    return [a ^ b for a, b in zip(x, y)]

# permute(circular shift) the input polynomial by delta bits
def perm(x, eta, delta, prt=False):
    ans = x
    if eta > 0:
        for i in range(eta):
            ans = ans[delta:] + ans[:delta]
            if prt:
                print("Perm #%d executed, x = %s;" %(i , ans))
    else:
        if prt:
            print("Perm not executed, x = %s;" % ans)
    return ans

# permute(circular shift) the input polynomial by delta bits with constant-time setup
def perm_constant(x, eta, delta, v, prt=False):
    ans = x
    for i in range(v):
        if i < eta:
            ans = ans[delta:] + ans[:delta]
            if prt:
                print("Perm #%d EXECUTED, x = %s;" %(i , ans))
        else:
            if prt:
                print("Perm #%d NOT executed, x = %s;" %(i , ans))
    return ans

# shift the input polynomial using perm() according to the proposed algorithm
def shift_algo(x, delta, v, prt=False):
    n = len(x)
    logN_b_v = math.ceil(math.log(n,v))
    k = logN_b_v
    ans = x
    for j in range(k):
        p = v**(k-j-1)
        eta = delta // p
        if prt:
            print("Round #%d, p = %d; eta = %d; bits to shift = %d; bits left = %d;" %(j, p, eta, delta, delta%p))
        delta %= p
        ans = perm(ans, eta, p, prt)
        if prt:
            print("")
    return ans

# shift the input polynomial using perm_constant() according to the proposed constant timing strategy
def shift_constant(x, delta, v, prt=False):
    n = len(x)
    logN_b_v = math.ceil(math.log(n,v))
    k = logN_b_v
    ans = x
    for j in range(k):
        p = v**(k-j-1)
        eta = delta // p
        if prt:
            print("Round #%d, p = %d; eta = %d; bits to shift = %d; bits left = %d;" %(j, p, eta, delta, delta%p))
        delta %= p
        ans = perm_constant(ans, eta, p, v, prt)
        if prt:
            print("")
    return ans

# Calculation of polynomial multiplication in theoretical way
# x: dense polynomial, represented by a list;
# idx: list of indices of 1's in the sparse polynomial
def mul_theo(x, idx, prt=False):
    ans = [0] * len(x)
    for i in range(len(idx)):
        x_shift = cir_shift(x, idx[i])
        if prt:
            print("x_shift: ", x_shift)
        ans = xor_bitwise(ans, x_shift)
        if prt:
            print("ans: ",ans)
    return ans

def mul_algo(x, idx, v, prt=False):
    ans = [0] * len(x)
    x_shift = x
    for i in range(len(idx)):
        delta = idx[i] - idx[i-1] if i > 0 else idx[0]
        x_shift = shift_algo(x_shift, delta, v, prt)
        ans = xor_bitwise(ans, x_shift)
    return ans

def mul_constant(x, idx, v, prt=False):
    ans = [0] * len(x)
    x_shift = x
    for i in range(len(idx)):
        if prt:
            print("IDX #%d" %i)
        delta = idx[i] - idx[i-1] if i > 0 else idx[0]
        x_shift = shift_constant(x_shift, delta, v, prt)
        ans = xor_bitwise(ans, x_shift)
        if prt:
            print("Shift done, x = %s", x_shift)
            print("XOR done, ans = %s", ans)
    return ans

# generate .do file for simulation
# x: dense polynomial, represented as a list
# w: indices, represented as a list 
# v: shift base
# len_ld: load width
def tb_gen(x, w, v, len_ld):
    n = len(x)
    logN_b_v = math.ceil(math.log(n,v))
    k = logN_b_v
    rd_ld = math.ceil(n/len_ld)
    # padding 0's in front to the nearst multiple of len_ld
    x = [0] * (rd_ld * len_ld - n) + x 
    contents = [
        "# delta inputs starts from 15ns\n",
        "restart -f\n",
        "force clk 0 0ns, 1 5ns -r 10 ns\n",
        "force rst 1 0ns, 0 15ns\n"
    ]
    x_in = "force d "
    for i in range(rd_ld):
        x_part = x[i*len_ld:(i+1)*len_ld]
        x_in += (''.join(map(str, x_part)) + " " + str(15+i*10) + "ns, ")
    P_start_time = (rd_ld-1)*10 + 15 + 10
    x_in = x_in[:-2] + "\n"
    P = [w[0]] + [w[i] - w[i-1] for i in range(1, len(w))]
    P_in = "force delta "
    for i in range(len(P)):
        P_in += (bin(P[i])[2:].zfill(16) + " " + str(P_start_time + i*(k*v+1)*10) + "ns, ")
    P_in = P_in[:-2] + "\n"
    run_time = P_start_time + len(P)*(k*v+1)*10 + rd_ld*10 + 10
    contents += [x_in, P_in, "run " + str(run_time) + "ns"]
    # change current working directory to the one containing this script
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    with open("test_mul_gen.do", "w") as f:
        f.writelines(contents)
    print("## test_mul_gen.do generated! :)")

def gen_index(n, omega):
    idx_set = set()
    # generate omega unique indices
    while len(idx_set) < omega:
        idx_set.add(random.randint(0, n-1))
    delta = sorted(list(idx_set))   # Actually no need to sort the indices, just for better visualization
    return delta
    
if __name__ == '__main__':
    n = 17669   # polynomial degree
    l_omega = 75   # the number of indices
    v = 2
    ld_width = 1
    x = [random.randint(0,2**32-1)%2 for _ in range(n)]
    delta_idx = gen_index(n, l_omega)

    use_test_case = 4

    # -- small scale test 1 --
    if use_test_case == 1:
        n = 16
        l_omega = 1
        v = 4
        ld_width = 4
        x = [1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1]
        delta_idx = [15]

    # -- small scale test 2 --
    if use_test_case == 2:
        n = 16
        l_omega = 2
        v = 4
        ld_width = 4
        x = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
        delta_idx = [5, 15]

    # -- small scale test 3 --
    if use_test_case == 3:
        n = 16
        l_omega = 2
        v = 2
        ld_width = 5
        x = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
        delta_idx = [0, 8]

    # -- mid scale test 4 --
    if use_test_case == 4:
        n = 816
        l_omega = 25
        v = 2
        ld_width = 17
        x = [random.randint(0,2**32-1)%2 for _ in range(n)]
        delta_idx = gen_index(n, l_omega)

    # print intermediate permutation results and generated .do file for testbench
    tb_gen(x, delta_idx, v, ld_width)

    # print(f"x: {x}")
    # print(f"omega: {delta_idx}")
    # print(f"expected outcome: {mul_constant(x, delta_idx, v, False)}")

    write_KAT = 0
    if write_KAT:
        # write to file KAT.txt
        s = "### Known Answer Case ###\n"
        s += f"n: {n}\n, l_omega: {l_omega}\n, v: {v}\n, ld_width: {ld_width}\n"
        s += f"x: {x}\n"
        s += f"omega: {delta_idx}\n"
        s += f"expected outcome: {mul_constant(x, delta_idx, v, False)}\n"
        # append to KAT.txt
        with open("KAT.txt", "a") as f:
            f.write(s)
