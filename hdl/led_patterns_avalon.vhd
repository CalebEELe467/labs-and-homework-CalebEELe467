library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity led_patterns_avalon is
  port (
    clk : in std_ulogic;
    rst : in std_ulogic;
    -- avalon memory-mapped slave interface
    avs_read      : in std_logic;
    avs_write     : in std_logic;
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    -- external I/O; export to top-level
    push_button : in std_ulogic;
    switches    : in std_ulogic_vector(3 downto 0);
    led         : out std_ulogic_vector(7 downto 0)
  );
end entity led_patterns_avalon;

architecture led_patterns_avalon_arch of led_patterns_avalon is
  signal hps_led_control     : std_logic_vector (31 downto 0) := "00000000000000000000000000000000";
  signal base_period         : std_logic_vector (31 downto 0) := "00000000000000000000000000001000";
  signal led_reg             : std_logic_vector (31 downto 0) := "00000000000000000000000000000000";
  signal led_control_boolean : boolean                        := false;
  component led_patterns is
    generic (
      system_clock_period : time := 20 ns
    );
    port (
      clk             : in std_logic;
      rst             : in std_logic;
      push_button     : in std_logic;
      switches        : in std_ulogic_vector(3 downto 0);
      hps_led_control : in boolean;
      base_period     : in unsigned(7 downto 0); -- Fixed point representation of time in seconds XXXX.XXXX
      led_reg         : in std_logic_vector(7 downto 0);
      led             : out std_ulogic_vector(7 downto 0)
    );
  end component;
begin
  led_patterns_inst : led_patterns
  generic map(
    system_clock_period => 20 ns
  )
  port map(
    clk             => clk,
    rst             => rst,
    push_button     => push_button,
    switches        => switches,
    hps_led_control => led_control_boolean,
    base_period     => unsigned(base_period(7 downto 0)),
    led_reg         => led_reg(7 downto 0),
    led             => led
  );

  hps_led_control_process : process (clk)
  begin
    if hps_led_control(0) = '1' then
      led_control_boolean <= true;
    else
      led_control_boolean <= false;
    end if;
  end process hps_led_control_process;

  avalon_register_read : process (clk)
  begin
    if rising_edge(clk) and avs_read = '1' then
      case avs_address is
        when "00" =>
          avs_readdata <= hps_led_control;
        when "01" =>
          avs_readdata <= base_period;
        when "10" =>
          avs_readdata <= led_reg;
        when others             =>
          avs_readdata <= (others => '0');
      end case;
    end if;
  end process avalon_register_read;

  avalon_register_write : process (clk, rst)
  begin
    if rst = '1' then
      hps_led_control <= "00000000000000000000000000000000";
      base_period     <= "00000000000000000000000000001000";
      led_reg         <= "00000000000000000000000000000000";

    elsif rising_edge(clk) and avs_write = '1' then
      case avs_address is
        when "00" =>
          hps_led_control <= avs_writedata;
        when "01" =>
          base_period <= avs_writedata;
        when "10" =>
          led_reg <= avs_writedata;
        when others =>
          null;
      end case;
    end if;
  end process avalon_register_write;

end architecture;