LIBRARY ieee;               
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

entity reg_aclr_en_1bit is
port (
		clk:  in std_logic;
		clr, en:  in std_logic;
		d:    in std_logic;
		e:    out std_logic
	);
end reg_aclr_en_1bit;

architecture arch of reg_aclr_en_1bit is
begin 
process(clr,clk)
begin
	if clr='1' then
		e<='0';
	else
		if en='1' then
			if(clk'event and clk='1') then
				e<=d;
			end if;
		end if;
	end if;
end process;
end arch;