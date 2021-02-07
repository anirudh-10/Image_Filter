library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity RAM_64Kx8 is
 port (
 clock : in std_logic;
 read_enable, write_enable : in std_logic; -- signals that enable read/write operation
 address : in std_logic_vector(15 downto 0); -- 2^16 = 64K
 data_in : in std_logic_vector(7 downto 0);
 data_out : out std_logic_vector(7 downto 0)
 );
end RAM_64Kx8;
entity ROM_32x9 is
 port (
 clock : in std_logic;
 read_enable : in std_logic; -- signal that enables read operation
 address : in std_logic_vector(4 downto 0); -- 2^5 = 32
 data_out : out std_logic_vector(7 downto 0)
 );
end ROM_32x9;
entity MAC is
 port (
 clock : in std_logic;
 control : in std_logic; -- ‘0’ for initializing the sum
 data_in1, data_in2 : in std_logic_vector(17 downto 0);
 data_out : out std_logic_vector(17 downto 0)
 );
end MAC;
architecture Artix of RAM_64Kx8 is
 type Memory_type is array (0 to 65535) of std_logic_vector (7 downto 0);
 signal Memory_array : Memory_type;
begin
 process (clock) begin
 if rising_edge (clock) then
 if (read_enable = '1') then -- the data read is available after the clock edge
 data_out <= Memory_array (to_integer (unsigned (address)));
 end if;
 if (write_enable = '1') then -- the data is written on the clock edge
 Memory_array (to_integer (unsigned(address))) <= data_in;
 end if;
 end if;
 end process;
end Artix;
architecture Artix of ROM_32x9 is
 type Memory_type is array (0 to 31) of std_logic_vector (8 downto 0);
 signal Memory_array : Memory_type;
begin
 process (clock) begin
 if rising_edge (clock) then
 if (read_enable = '1') then -- the data read is available after the clock edge
 data_out <= Memory_array (to_integer (unsigned (address)));
 end if;
 end if;
 end process;
end Artix;
architecture Artix of MAC is
 signal sum, product : signed (17 downto 0);
begin
 data_out <= std_logic_vector (sum);
 product <= signed (data_in1) * signed (data_in2)
 process (clock) begin
 if rising_edge (clock) then -- sum is available after clock edge
 if (control = '0') then -- initialize the sum with the first product
 sum <= std_logic_vector (product);
 else -- add product to the previous sum
 sum <= std_logic_vector (product + signed (sum));
 end if;
 end if;
 end process;
end Artix;
entity assignment3 is
	port (
		clock : in std_logic;
		push_btn : in std_logic; -- filtering starts when button is pressed once 
		switch : in std_logic -- if 1 then smoothening else sharpening
		);
end assignment3;
--
-- initially the state is idle
-- when push button is pressed the state changes from idle to S and filtering process starts. 
-- When the state is S pressing the push button will not affect the state and filtering will go on as in normal case.
-- The mode of the swtich button is read when the push button is pressed and changing the switch button after that will not affect the output.
-- When filtering completes the state changes back from S to idle 
--
architecture behaviour of assignment3 is
signal i : integer; -- is used as a counter to calculate sum of product of pair of 9 values.
type state_type is (idle,S); -- 2 states idle and S. when push button is pressed state changes from idle to S and when filtering is completed state changes back from S to idle.
signal state : state_type := idle; -- initializing the state as idle
signal to_read_RAM : std_logic; -- if 1 then reading the pixel at the specified location is enabled in RAM
signal to_read_ROM : std_logic; -- if 1 then reading the coefficent value at the specified location is enabled in ROM
signal temp_control : std_logic; -- if 1 then product of pairs will be added to the existing sum else sum will be re-initialized
signal location_RAM :std_logic_vector(15 downto 0); -- to specify the location in the RAM where pixel has to be read or written
signal temp_location_RAM_READ :std_logic_vector(15 downto 0); -- temporary signal that travels the cells of the sliding 3x3 window for a particular center
signal temp_location_RAM_WRITE :std_logic_vector(15 downto 0); -- temporary signal that specifies where to write the pixel in the RAM
signal center_of_RAM_READ :std_logic_vector(15 downto 0); -- specifies the center of the 3x3 window i.e. the cell to which pixel has to be written
signal location_ROM : std_logic_vector(4 downto 0); -- specifies the location in the ROM to read the coefficient value in the filter matrix
signal input_data : std_logic_vector(7 downto 0); --  input data for RAM
signal output_data : std_logic_vector(7 downto 0); -- used to store the output data for RAM
signal data_out_ROM : std_logic_vector(7 downto 0); -- used to store the output data for ROM
signal temp_data_in1 : std_logic_vector(17 downto 0); -- stores the first input  to be given to MAC
signal temp_data_in2 : std_logic_vector(17 downto 0); -- stores the second input to be given to MAC
signal temp_data_out : std_logic_vector(17 downto 0); -- used to store the output data from MAC
signal start_filtering : std_logic :='0'; -- to check if filtering is in process or not
signal button_already_pressed : std_logic :='1'; -- used to check if button is pressed while the filtering process is being done or not
begin
	-- instantiating the RAM, ROM and MAC entities
	RAM:
		ENTITY WORK.RAM_64Kx8(Artix)
		PORT MAP(clock,to_read_RAM,to_write,location_RAM,input_data,output_data);
	ROM:
		ENTITY WORK.ROM_32x9(Artix)
		PORT MAP(clock,to_read_ROM,location_ROM,data_out_ROM);
	mac:
		ENTITY WORK.MAC(Artix)
		PORT MAP(clock,temp_control,temp_data_in1,temp_data_in2,temp_data_out);
	process(clock)
		begin
			if(rising_edge(clock)) then
				if(push_btn and button_already_pressed and state = idle ) -- to check if push_btn is pressed and it was released after pressing and the current state is idle.
					start_filtering <= '1'; 
					state <= S;
					to_read_RAM <= '1';
					to_write <= '0';
					to_read_ROM <='1';
					button_already_pressed <= '0';
					temp_location_RAM_WRITE <= std_logic_vector(to_unsigned(32768,16)); -- initialze it to the first writing location in RAM
					center_of_RAM_READ <= std_logic_vector(to_unsigned(161,16)); --  initialize it to the 2nd column of 2nd row
					-- initialize the ROM address according to switch (if 1 then smoothening else sharpening)
					-- smoothening is from 0 address and sharpening is from 16 address
					if(switch) then
						location_ROM <= std_logic_vector(to_unsigned(0,5));
					else
						location_ROM <= std_logic_vector(to_unsigned(16,5));
					end if;
				end if;
			end if;
			-- when push button released change the state of button_already_pressed
			if(rising_edge(clock)) then
				if(push_btn = '0') then
					button_already_pressed <= '1';
				end if;
			end if;
			if(start_filtering and rising_edge(clock)) then
				-- if 0 then reach the top left position of the 3x3 sliding window
				-- when we reach end of the row in 3x3 sliding window then i%3=0 and we add 158 to reach the next row of the sliding window
				-- else we just add 1 to reach the next column in the same row of the sliding window
				if(i = 0) then
					temp_location_RAM_READ <= std_logic_vector(to_unsigned(to_integer(unsigned(center_of_RAM_READ))-161,16)); 
				elsif(i rem 3 = 0) then
						temp_location_RAM_READ <= std_logic_vector(to_unsigned(to_integer(unsigned(center_of_RAM_READ))+158,16));
				else
				 		temp_location_RAM_READ <= std_logic_vector(to_unsigned(to_integer(unsigned(center_of_RAM_READ))+1,16));  
				end if;
				-- we will get the first output data from RAM and ROM after 2 clock cycles hence when i=2 we update temp_control to 0 to initialize the sum in the MAC
				-- else temp_control is kept 1
				if(i = 2) then
					temp_control = '0';
				else
					temp_control = '1';
				end if;
				to_read_RAM <= '1';-- reading of value is done here
				to_write <= '0';
				location_RAM <= temp_location_RAM_READ;
				temp_data_in1 <= std_logic_vector(to_signed(to_integer(unsigned(output_data)),18)); -- convert the 8 bit logic vector to 18 bit logic vector
				temp_data_in2 <= std_logic_vector(to_signed(to_integer(signed(data_out_ROM)),18)); -- convert the 8 bit logic vector to 18 bit logic vector  -- in ROM the data stored is signed
				location_ROM <= std_logic_vector(to_unsigned(to_integer(unsigned(location_ROM))+1,5)); --	add 1 to the location_ROM to reach the next coefficient of filtering matrix. 
				i<=i+1; -- increment i by 1
				-- we will get the final output from mac after 2 clock cycles when we send the 9th input. At i=10 we will send the 9th input . Hence we will get the final output from mac at i=12
				if(i=12) then
					to_write <= '1'; -- in this we write the value in the RAM
					to_read <= '0';
					location_RAM <= temp_location_RAM_WRITE; -- location at which we have to write
					-- if it is negative i.e. leftmost bit is 1 then we convert it to 0 else we scale it down to 8 bits
					if(temp_data_out(17)) then
						output_data <= "00000000";
					else
						output_data <= temp_data_out(14 downto 7);
					end if;
					i <= 0; -- reset i to 0
					-- reset location_ROM according to switch
					if(switch) then
						location_ROM <= std_logic_vector(to_unsigned(0,5));
					else
						location_ROM <= std_logic_vector(to_unsigned(16,5));
					end if;
					--update RAM_write variable
					-- increment it by 1 everytime
					temp_location_RAM_WRITE <= std_logic_vector(to_unsigned(to_integer(unsigned(temp_location_RAM_WRITE))+1,16));
					--increment center_of_RAM_READ by 1 and if we reach the last column then add 2 more so that we reach the 2nd column of the next row
					center_of_RAM_READ <= std_logic_vector(to_unsigned(to_integer(unsigned(center_of_RAM_READ))+1,16));
					if(to_integer(unsigned(center_of_RAM_READ)) rem 160 = 159) then
						center_of_RAM_READ <= std_logic_vector(to_unsigned(to_integer(unsigned(center_of_RAM_READ))+3,16));
					end if;
					-- total values to be written is 118*158. Hence the last address at which value would be written would be 32768+118*158-1=51411.
					--And when writing location is 51412 we stop the filtering process and change the state back to idle
					if(to_integer(unsigned(temp_location_RAM_WRITE))= 51412) then
						start_filtering <= '0';
						state <= idle;
						i <= 0;
						to_write <= '0';
						to_read_RAM <= '0';
						to_read_ROM <= '0';
					end if;
				end if;
			end if;
		end process;
end behaviour; 