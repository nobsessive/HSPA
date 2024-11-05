use work.util_pkg.all;

package hspa_pkg is
    constant HSPA_N   : integer := 816; -- polynomial degree
    constant HSPA_W   : integer := 25;  -- Hamming weight of the polynomial
    constant HSPA_V   : integer := 2;  -- coefficient permutation base 
    constant HSPA_LW  : integer := 17;  -- load width
    -- derived constants
    constant HSPA_LOGN_B_V : integer := clogv(HSPA_N, HSPA_V);
    constant HSPA_SEL_WIDTH : integer := clog2(HSPA_LOGN_B_V);
    constant HSPA_LOGV_B_2  : integer := clog2(HSPA_V);
    constant HSPA_IO_D_RND  : integer := HSPA_N / HSPA_LW; -- the number of load cycles
end hspa_pkg;

