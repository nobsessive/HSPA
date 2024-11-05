LIBRARY ieee;               
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

entity acc is 
	generic (N:INTEGER:=17669; len_out:INTEGER:=16);
	port(   clk, clr, en, csh: in std_logic;
		    d: in std_logic_vector(N-1 downto 0);
		    q: out std_logic_vector(len_out-1 downto 0)
			);
end entity;

architecture arch of acc is

component reg_aclr_en_1bit is
	port (  clk:  in std_logic;
			clr, en:  in std_logic;
			d:    in std_logic;
			e:    out std_logic
			);
end component;

signal din, dout: std_logic_vector(N-1 downto 0);
signal f, g: std_logic_vector(N-1 downto 0);

begin
	g1: for i in 0 to N-1 generate
			comp1: reg_aclr_en_1bit port map(clk=>clk, clr=>clr, en=>'1', d=>din(i), e=>dout(i));
			din(i) <= dout(i) when en='0' else
				  g(i) when csh='1' else
				  f(i) when csh='0';
		end generate;
		
	g2: for i in 0 to N-1 generate
			f(i) <= d(i) xor dout(i);
		end generate;
		
	g3: for i in len_out to N-1 generate
			g(i) <= dout(i-len_out);
		end generate;
		
	g4: for i in 0 to len_out-1 generate
	        g(i) <= dout(N-len_out+i);
	    end generate;
		
	q <= dout(N-1 downto N-len_out);

end arch;