## HSPA

This repository provides the hardware implementation code for HSPA, a  High-throughput Sparse Polynomial multiplication
Accelerators for code-based post-quantum cryptography. Associated test scripts and cases are provided for easier evaluation and further works. 

## Running the tests
1. Specify user defined parameters (n, l_omega, v, ld_width) in top test script: scripts/hspa_test.py. Run the test script to generate the test file "test_mul_gen.do".
2. Replace user defined parameters in HDL package file: hspa_pkg.vhd according to the test case. 
3. Use simulation tool to run the test file "test_mul_gen.do" and check the result.

## Contributors
Pengzhou He phe@villanova.edu \
Yazheng Tu ytu1@villanova.edu \
Tianyou Bao tbao@villanova.edu \
ÇETIN KAYA KOÇ cetinkoc@ucsb.edu \
Jiafeng Xie jiafeng.xie@villanova.edu

If you use HSPA in research or study works, please cite to:

```
@article{hspa,
author = {He, Pengzhou and Tu, Yazheng and Bao, Tianyou and Kaya Koç, Çetin and Xie, Jiafeng},
title = {HSPA: High-Throughput Sparse Polynomial Multiplication Accelerators for Code-based Post-Quantum Cryptography},
year = {2024},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
volume = {},
number = {},
pages = {1-23},
journal = {ACM Trans. Embed. Comput. Syst.}
}
```