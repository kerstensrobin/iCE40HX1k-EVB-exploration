library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        CLK  : in  std_logic;
        BUT1 : in  std_logic;
        BUT2 : in  std_logic;
        LED1 : out std_logic;
        LED2 : out std_logic
    );
end entity top;

architecture rtl of top is
    -- At 100 MHz: toggle every 50M cycles = 0.5 s per phase
    constant BLINK_MAX    : natural := 50_000_000 - 1;
    -- Debounce: sample buttons every ~1 ms
    constant DEBOUNCE_MAX : natural := 100_000 - 1;

    signal blink_cnt   : natural range 0 to BLINK_MAX    := 0;
    signal debounce_cnt: natural range 0 to DEBOUNCE_MAX := 0;

    signal blink_tick  : std_logic := '0';
    signal debounce_tick: std_logic := '0';
    signal blink_state : std_logic := '0';

    signal but1_r, but2_r : std_logic := '1';
    signal mode : std_logic := '0';
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            blink_tick <= '0';
            if blink_cnt = BLINK_MAX then
                blink_cnt  <= 0;
                blink_tick <= '1';
            else
                blink_cnt <= blink_cnt + 1;
            end if;
        end if;
    end process;

    process(CLK)
    begin
        if rising_edge(CLK) then
            if blink_tick = '1' then
                blink_state <= not blink_state;
            end if;
        end if;
    end process;

    process(CLK)
    begin
        if rising_edge(CLK) then
            debounce_tick <= '0';
            if debounce_cnt = DEBOUNCE_MAX then
                debounce_cnt  <= 0;
                debounce_tick <= '1';
            else
                debounce_cnt <= debounce_cnt + 1;
            end if;
        end if;
    end process;

    -- Sample buttons and toggle mode when both pressed (active low)
    process(CLK)
    begin
        if rising_edge(CLK) then
            if debounce_tick = '1' then
                but1_r <= BUT1;
                but2_r <= BUT2;
                if but1_r = '0' and but2_r = '0' then
                    mode <= not mode;
                end if;
            end if;
        end if;
    end process;

    -- Mode 0: LEDs mirror buttons; Mode 1: LEDs blink in opposition
    LED1 <= not but1_r  when mode = '0' else blink_state;
    LED2 <= not but2_r  when mode = '0' else not blink_state;

end architecture rtl;
