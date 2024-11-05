LIBRARY ieee;               
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity ctrl_unit is
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
end entity;


architecture arch of ctrl_unit is

type statetype is (strst, load_d, shift, shift_out, output, stdone);
signal state: statetype;
signal cnt_c: unsigned (15 downto 0); -- counter for cycle during load/output;
signal cnt_r: unsigned (sel_width-1 downto 0); -- counter for round (upper limit is #of v^i);
signal cnt_w: unsigned (7 downto 0); -- counter for w, up to 149; Note: should be modified for BIKE implementation;
signal cnt_v: unsigned (logv_b_2-1 downto 0); -- counter for v;
signal n_shift: integer range 0 to N-1 := 0; -- shift count with v^i;
signal sel_int: integer range 0 to N-1 := 0;
signal shift_left: integer range -N+1 to N-1 := 0;
signal v_i: integer range 0 to N-1 := 0; -- shift amount;
signal shifted: std_logic; -- flag that whether a shift was performed at previous cycle;
 
begin

	-- state/counter register
	p1: process(rst, clk, state)
		begin
			if rst = '1' then			
				state <= strst;
				cnt_c <= (others=>'0');
				cnt_w <= (others=>'1');
				cnt_r <= (others=>'1');
				cnt_v <= (others=>'1');
			elsif clk'event and clk = '1' then
				case state is
					when strst =>
						state <= load_d;
					when load_d => 
						if cnt_c < io_d_rnd-1 then
							state <= load_d;
							cnt_c <= cnt_c + 1;
						else 
							state <= shift;
							cnt_c <= (others=>'0');
							cnt_r <= (others=>'0');
							cnt_v <= (others=>'0');
							cnt_w <= (others=>'0');
						end if;
					when shift => 
						if cnt_r < logN_b_v-1 then
							if cnt_v < v-1 then
								state <= shift;
								cnt_v <= cnt_v + 1;
							else
								state <= shift;
								cnt_r <= cnt_r + 1;
								cnt_v <= (others=>'0');
							end if;
						else
							if cnt_v < v-1 then
								state <= shift;
								cnt_v <= cnt_v + 1;
							else
								state <= shift_out;
								cnt_r <= (others=>'0');
								cnt_v <= (others=>'0');
							end if;
						end if;
						
					when shift_out =>
						if cnt_w < w-1 then
							state <= shift;
							cnt_w <= cnt_w + 1;
						else
							state <= output;
							cnt_w <= (others=>'0'); 
						end if;
						
					when output =>
						if cnt_c < io_d_rnd-1 then
							state <= output;
							cnt_c <= cnt_c + 1;
						else
							state <= stdone;
						end if;		
					when stdone =>
						state <= stdone;
				end case;
			end if;
		end process;
		
	-- output control
	p2: process(state, cnt_r, cnt_w, cnt_v)
		begin
			case state is
				when strst =>
					load_mcore <= '0';
					en_acc <= '0';
					clr_acc <= '1';
					done <= '0';
					v_i <= 1;
					csh_acc <= '0';

				when load_d =>
					load_mcore <= '1';
				
				when shift =>
					v_i <= (v**(logN_b_v-1-to_integer(cnt_r)));
					load_mcore <= '0';
					clr_acc <= '0';
					csh_acc <= '0';
					en_acc <= '0';
				
				when shift_out =>
					en_acc <= '1';

				when output =>
					en_acc <= '1';
					csh_acc <= '1';
					
				when stdone =>
					done <= '1';
				
			end case;

		end process;

	-- claculate amount and how many times to shift 
	p3:process(cnt_v, shifted, state)
	   variable shift_left_v: integer range 0 to N-1 := 0;
	   begin
		if state = shift then
			if cnt_r = 0 and cnt_v = 0 then
				shift_left_v := to_integer(unsigned(delta));
			elsif shifted = '1' then
				shift_left_v := shift_left_v - v_i;
			else
				shift_left_v := shift_left_v;	
			end if;
		else
			shift_left_v := 0;
		end if;
		shift_left <= shift_left_v;
	   end process;
	
	p4: process(v_i)
	    variable n_shift_v: integer range 0 to N-1 := 0;
		variable sel_v: std_logic_vector(sel_width-1 downto 0);
	    begin	
		if state = shift and cnt_v = 0 then
			n_shift_v := shift_left / v_i;
		else
			n_shift_v := 0;
		end if;
		sel_v := std_logic_vector(to_unsigned(logN_b_v-1-to_integer(cnt_r), sel_width));
		sel <= sel_v;
		n_shift <= n_shift_v;
	    end process;
	
	-- determine whether a shift was operated at the previous cycle or not
	p5: process(clk, state)
	    begin
		if clk'event and clk='1' then
			shifted <= en_mcore;
		end if;
	    end process;

	-- determine whether to shift at current cycle or not
	en_mcore <= '1' when cnt_v <= n_shift-1 and v_i <= shift_left else '0';
	
	dout_valid <= '1' when state = output else '0';
	
end arch;


