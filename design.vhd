library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux8 is
  port (data : in std_logic_vector(7 downto 0);
        sel  : in std_logic_vector(2 downto 0);
        y    : out std_logic);
end entity;

architecture dataflow of mux8 is
begin
  y <= data(to_integer(unsigned(sel)));
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity demux8 is
  port (din : in std_logic;
        sel : in std_logic_vector(2 downto 0);
        y   : out std_logic_vector(7 downto 0));
end entity;

architecture dataflow of demux8 is
  alias s2 : std_logic is sel(2);
  alias s1 : std_logic is sel(1);
  alias s0 : std_logic is sel(0);
begin
  y(0) <= din and (not s2) and (not s1) and (not s0);
  y(1) <= din and (not s2) and (not s1) and s0;
  y(2) <= din and (not s2) and s1       and (not s0);
  y(3) <= din and (not s2) and s1       and s0;
  y(4) <= din and s2       and (not s1) and (not s0);
  y(5) <= din and s2       and (not s1) and s0;
  y(6) <= din and s2       and s1       and (not s0);
  y(7) <= din and s2       and s1       and s0;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
  port (a, b, cin : in std_logic;
        sum, cout : out std_logic);
end entity;

architecture dataflow of full_adder is
begin
  sum  <= a xor b xor cin;
  cout <= (a and b) or ((a xor b) and cin);
end architecture;

architecture behavioral of full_adder is
begin
  process (all)
    variable count_ones : integer range 0 to 3;
  begin
    count_ones := 0;
    if a = '1' then count_ones := count_ones + 1; end if;
    if b = '1' then count_ones := count_ones + 1; end if;
    if cin = '1' then count_ones := count_ones + 1; end if;

    if (count_ones mod 2) = 1 then sum <= '1';
    else sum <= '0'; end if;
    if count_ones >= 2 then cout <= '1';
    else cout <= '0'; end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity full_subtractor is
  port (a, b, bin : in std_logic;
        diff, bout : out std_logic);
end entity;

architecture dataflow of full_subtractor is
begin
  diff <= a xor b xor bin;
  bout <= ((not a) and b) or ((not (a xor b)) and bin);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity sr_ff is
  port (clk, rst, s, r : in std_logic;
        q : out std_logic);
end entity;

architecture behavioral of sr_ff is
  signal state : std_logic := '0';
begin
  process (clk, rst)
  begin
    if rst = '1' then
      state <= '0';
    elsif rising_edge(clk) then
      case s & r is
        when "00" => null;
        when "01" => state <= '0';
        when "10" => state <= '1';
        when others => state <= 'X';
      end case;
    end if;
  end process;
  q <= state;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity jk_ff is
  port (clk, rst, j, k : in std_logic;
        q : out std_logic);
end entity;

architecture behavioral of jk_ff is
  signal state : std_logic := '0';
begin
  process (clk, rst)
  begin
    if rst = '1' then
      state <= '0';
    elsif rising_edge(clk) then
      case j & k is
        when "00" => null;
        when "01" => state <= '0';
        when "10" => state <= '1';
        when others => state <= not state;
      end case;
    end if;
  end process;
  q <= state;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity binary_to_gray4 is
  port (binary : in std_logic_vector(3 downto 0);
        gray   : out std_logic_vector(3 downto 0));
end entity;

architecture dataflow of binary_to_gray4 is
begin
  gray <= binary xor ('0' & binary(3 downto 1));
end architecture;
