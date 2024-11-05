library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.hspa_pkg.all;

entity hspa_mul is
	generic (N:INTEGER:=HSPA_N;
			 w:INTEGER:=HSPA_W;
			 v : integer := HSPA_V; -- input number of pointwise muxes; 
             logN_b_v : integer := HSPA_LOGN_B_V; -- ceil(logv(N));
			 sel_width : integer := HSPA_SEL_WIDTH; -- ceil(log2(logN_b_v)) ;
			 logv_b_2: integer:=HSPA_LOGV_B_2; -- log2(v);
			 load_width:INTEGER:=HSPA_LW; 
			 io_d_rnd:INTEGER:=HSPA_IO_D_RND -- ceil(N/load_width); 
			 ); 
    port ( clk, rst  : in std_logic;
		   delta     : in std_logic_vector(15 downto 0); -- delta_prime = P[i] - P[i-1];
           d 	     : in std_logic_vector(load_width-1 downto 0);
           w_out     : out std_logic_vector(load_width-1 downto 0);
		   dout_valid: out std_logic;
           done      : out std_logic
		   );
end hspa_mul;

architecture arch of hspa_mul is 

component mcore is
    generic (
        N : integer := 9;
        v : integer := 2; -- input number of pointwise muxes
        logN_b_v : integer := 4; -- ceil(logv(N))
        sel_width : integer := 2; -- ceil(log2(logN_b_v)) 
        load_width : integer := 2 -- load width
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        load : in std_logic;
        sel : in std_logic_vector(sel_width-1 downto 0);
        din : in std_logic_vector(load_width-1 downto 0);
        dout : out std_logic_vector(N-1 downto 0)
    );

end component;

component acc is 
	generic (N:INTEGER:=9; len_out:INTEGER:=2);
	port(   clk, clr, en, csh: in std_logic;
		    d: in std_logic_vector(N-1 downto 0);
		    q: out std_logic_vector(len_out-1 downto 0)
			);
end  component;

component ctrl_unit is
	generic (N:INTEGER:=9;
			 w:INTEGER:=4;
			 v : integer := 4; -- input number of pointwise muxes; 
             logN_b_v : integer := 2; -- ceil(logv(N));
			 sel_width : integer := 1; -- ceil(log2(logN_b_v)) ;
			 logv_b_2: integer:=2; -- log2(v);
			 load_width:INTEGER:=2; 
			 io_d_rnd:INTEGER:=5 -- ceil(N/load_width); 
			 ); 
	port (	clk, rst :					in std_logic;
			delta :					    in std_logic_vector(15 downto 0); -- delta_prime = P[i] - P[i-1];
			en_mcore, load_mcore : 		out std_logic;
			en_acc, clr_acc, csh_acc : 	out std_logic;
			sel:						out std_logic_vector(sel_width-1 downto 0);
			dout_valid:					out std_logic;
			done : 						out std_logic
			);
end component;

signal en_mcore_s, load_mcore_s, en_acc_s, clr_acc_s, csh_acc_s: std_logic;
signal sel_s: std_logic_vector(sel_width-1 downto 0);
signal mcore_out: std_logic_vector(N-1 downto 0);

begin 
	
	u0: ctrl_unit generic map(N=>N, w=>w, v=>v, logN_b_v=>logN_b_v, sel_width=>sel_width, logv_b_2=>logv_b_2, load_width=>load_width, io_d_rnd=>io_d_rnd)
				  port map(clk=>clk, rst=>rst, delta=>delta, en_mcore=>en_mcore_s, load_mcore=>load_mcore_s, en_acc=>en_acc_s, clr_acc=>clr_acc_s, 
						   csh_acc=>csh_acc_s, sel=>sel_s, dout_valid=>dout_valid, done=>done);
	
	u1:  mcore generic map(N=>N, v=>v, logN_b_v=>logN_b_v, sel_width=>sel_width, load_width=>load_width)
               port map(clk=>clk, rst=>rst, en=>en_mcore_s, load=>load_mcore_s, sel=>sel_s, din=>d, dout=>mcore_out);
    
	u2: acc generic map(N=>N, len_out=>load_width)
			port map(clk=>clk, clr=>clr_acc_s, en=>en_acc_s, csh=>csh_acc_s, d=>mcore_out, q=>w_out);


end arch;