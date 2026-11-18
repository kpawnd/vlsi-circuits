library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_lab is
end entity;

architecture sim of tb_lab is
  signal data : std_logic_vector(7 downto 0) := (others => '0');
  signal sel : std_logic_vector(2 downto 0) := (others => '0');
  signal mux_y, din : std_logic := '0';
  signal demux_y : std_logic_vector(7 downto 0);

  signal a, b, cin, bin : std_logic := '0';
  signal sum_data, cout_data, sum_beh, cout_beh : std_logic;
  signal diff, bout : std_logic;

  signal binary, gray : std_logic_vector(3 downto 0) := (others => '0');
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal s, r, j, k : std_logic := '0';
  signal sr_q, jk_q : std_logic;
begin
  u_mux : entity work.mux8(dataflow)
    port map (data => data, sel => sel, y => mux_y);
  u_demux : entity work.demux8(dataflow)
    port map (din => din, sel => sel, y => demux_y);
  u_adder_data : entity work.full_adder(dataflow)
    port map (a => a, b => b, cin => cin, sum => sum_data, cout => cout_data);
  u_adder_beh : entity work.full_adder(behavioral)
    port map (a => a, b => b, cin => cin, sum => sum_beh, cout => cout_beh);
  u_subtractor : entity work.full_subtractor(dataflow)
    port map (a => a, b => b, bin => bin, diff => diff, bout => bout);
  u_gray : entity work.binary_to_gray4(dataflow)
    port map (binary => binary, gray => gray);
  u_sr : entity work.sr_ff(behavioral)
    port map (clk => clk, rst => rst, s => s, r => r, q => sr_q);
  u_jk : entity work.jk_ff(behavioral)
    port map (clk => clk, rst => rst, j => j, k => k, q => jk_q);

  clk <= not clk after 5 ns;

  stimulus : process
    variable expected_demux : std_logic_vector(7 downto 0);
    variable expected_gray : std_logic_vector(3 downto 0);
    variable ai, bi, ci, arithmetic_result : integer;
    variable expected_bit, expected_carry : std_logic;
  begin
    for word in 0 to 255 loop
      data <= std_logic_vector(to_unsigned(word, 8));
      for channel in 0 to 7 loop
        sel <= std_logic_vector(to_unsigned(channel, 3));
        wait for 1 ns;
        if ((word / (2 ** channel)) mod 2) = 1 then
          expected_bit := '1';
        else
          expected_bit := '0';
        end if;
        assert mux_y = expected_bit
          report "MUX mismatch: data=" & integer'image(word) &
                 " sel=" & integer'image(channel)
          severity failure;
      end loop;
    end loop;
    report "PASS mux: 2048 cases" severity note;

    for input_value in 0 to 1 loop
      if input_value = 0 then din <= '0'; else din <= '1'; end if;
      for channel in 0 to 7 loop
        sel <= std_logic_vector(to_unsigned(channel, 3));
        expected_demux := (others => '0');
        if input_value = 1 then expected_demux(channel) := '1'; end if;
        wait for 1 ns;
        assert demux_y = expected_demux
          report "DEMUX mismatch: din=" & integer'image(input_value) &
                 " sel=" & integer'image(channel)
          severity failure;
      end loop;
    end loop;
    report "PASS demux: 16 cases" severity note;

    for value in 0 to 7 loop
      ai := (value / 4) mod 2;
      bi := (value / 2) mod 2;
      ci := value mod 2;
      if ai = 1 then a <= '1'; else a <= '0'; end if;
      if bi = 1 then b <= '1'; else b <= '0'; end if;
      if ci = 1 then cin <= '1'; bin <= '1';
      else cin <= '0'; bin <= '0'; end if;
      wait for 1 ns;

      arithmetic_result := ai + bi + ci;
      if (arithmetic_result mod 2) = 1 then expected_bit := '1';
      else expected_bit := '0'; end if;
      if arithmetic_result >= 2 then expected_carry := '1';
      else expected_carry := '0'; end if;
      assert sum_data = expected_bit and cout_data = expected_carry
        report "Dataflow adder mismatch: row=" & integer'image(value)
        severity failure;
      assert sum_beh = expected_bit and cout_beh = expected_carry
        report "Behavioral adder mismatch: row=" & integer'image(value)
        severity failure;

      arithmetic_result := ai - bi - ci;
      if (arithmetic_result mod 2) = 1 then expected_bit := '1';
      else expected_bit := '0'; end if;
      if arithmetic_result < 0 then expected_carry := '1';
      else expected_carry := '0'; end if;
      assert diff = expected_bit and bout = expected_carry
        report "Subtractor mismatch: row=" & integer'image(value)
        severity failure;
    end loop;
    report "PASS both adders and subtractor: 8 rows each" severity note;

    for value in 0 to 15 loop
      binary <= std_logic_vector(to_unsigned(value, 4));
      expected_gray := (others => '0');
      if (value / 8) = 1 then expected_gray(3) := '1'; end if;
      for bit_index in 0 to 2 loop
        if ((value / (2 ** bit_index)) mod 2) /=
           ((value / (2 ** (bit_index + 1))) mod 2) then
          expected_gray(bit_index) := '1';
        end if;
      end loop;
      wait for 1 ns;
      assert gray = expected_gray
        report "Gray mismatch: binary=" & integer'image(value)
        severity failure;
    end loop;
    report "PASS binary-to-Gray: 16 cases" severity note;

    wait for 1 ns;
    assert sr_q = '0' and jk_q = '0'
      report "Flip-flop initial reset mismatch" severity failure;
    rst <= '0';
    s <= '0'; r <= '0'; j <= '0'; k <= '0';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '0' and jk_q = '0'
      report "Flip-flop hold mismatch" severity failure;

    s <= '1'; r <= '0'; j <= '1'; k <= '0';
    wait until falling_edge(clk); wait for 1 ns;
    assert sr_q = '0' and jk_q = '0'
      report "Flip-flop changed before the rising edge" severity failure;
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '1' and jk_q = '1'
      report "Flip-flop set mismatch" severity failure;

    s <= '0'; r <= '0'; j <= '0'; k <= '0';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '1' and jk_q = '1'
      report "Flip-flop hold-after-set mismatch" severity failure;

    j <= '1'; k <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '1' and jk_q = '0'
      report "JK first toggle mismatch" severity failure;
    wait until rising_edge(clk); wait for 1 ns;
    assert jk_q = '1'
      report "JK second toggle mismatch" severity failure;

    s <= '0'; r <= '1'; j <= '0'; k <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '0' and jk_q = '0'
      report "Flip-flop clear mismatch" severity failure;

    s <= '1'; r <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = 'X'
      report "SR invalid-state mismatch" severity failure;

    s <= '1'; r <= '0'; j <= '1'; k <= '0';
    wait until rising_edge(clk); wait for 1 ns;
    assert sr_q = '1' and jk_q = '1'
      report "Flip-flops must both be set before testing asynchronous reset"
      severity failure;

    rst <= '1';
    wait for 1 ns;
    assert sr_q = '0' and jk_q = '0'
      report "Flip-flop asynchronous reset mismatch" severity failure;
    report "PASS SR and JK flip-flop transitions" severity note;
    report "ALL TESTS PASSED" severity note;
    stop;
    wait;
  end process;
end architecture;
