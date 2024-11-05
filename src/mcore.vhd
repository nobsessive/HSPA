library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcore is
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

end mcore;

--
-- 1, 4, 16, 64, 256, 1024, 4096, 16384
--

architecture rtl of mcore is

    type vec_reg is array (natural range <>) of std_logic_vector(N-1 downto 0);
    signal reg_v : vec_reg(0 to 2**sel_width-1);
    signal reg_out : std_logic_vector(N-1 downto 0);
    signal reg_selected : std_logic_vector(N-1 downto 0);
    signal reg_in : std_logic_vector(N-1 downto 0);

    function perm(x : std_logic_vector(N-1 downto 0); p : integer) return std_logic_vector is
        variable y : std_logic_vector(N-1 downto 0);
    begin
        y := x(N-p-1 downto 0) & x(N-1 downto N-p);
    return y;
    end function;

begin
    
        process(clk, rst)
        begin
                if rst = '1' then
                    reg_out <= (others => '0');
                elsif clk'event and clk='1' then
                    reg_out <= reg_in;
                end if;
        end process;

        gp : for i in 0 to logN_b_v-1 generate
            reg_v(i) <= perm(reg_out, v**(i));         
        end generate;
	
        -- The mux before register array selects between shifted register out and selected permutation
        reg_in <= reg_out(N-load_width-1 downto 0) & din when load = '1' else reg_selected;
        
        -- Select the permutation of this stage. Permutation (v**sel) is determined by sel which is generated from an up-counter
        -- and remain constant during this stage and counted up by 1 in the next stage.
        reg_selected <= reg_v(to_integer(unsigned(sel))) when en = '1' else reg_out;
        


        dout <= reg_out;

    end rtl;
