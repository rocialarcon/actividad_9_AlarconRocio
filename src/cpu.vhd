library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity cpu is
    port(
        clk : in std_logic;
        nreset : in std_logic;
        --entrada: datos que leemos de la memoria  
        bus_dsm : in std_logic_vector ( 31 downto 0);
        --salidas: que direccion queremos y que datos escribimos
        bus_addr : out std_logic_vector (31 downto 0);
        bus_dms : out std_logic_vector (31 downto 0);
        bus_twidth : out std_logic_vector (2 downto 0);
        bus_tms : out std_logic
    );
end cpu;

architecture arch of cpu is
    --registros internos
    signal pc, pc_next : std_logic_vector ( 31 downto 0);
    signal ir : std_logic_vector ( 31 downto 0);
    signal pc_plus4 : std_logic_vector(31 downto 0);

    --cables de control
    signal jump, s1pc, wpc, wmem, wreg, sel_imm : std_logic;
    signal data_addr, mem_source, imm_source, winst : std_logic;
    signal alu_mode : std_logic_vector (1 downto 0);
    signal imm_mode : std_logic_vector (2 downto 0);
    signal take_branch : std_logic;
    -- ALU
    signal alu_a, alu_b, alu_y : std_logic_vector (31 downto 0);
    signal alu_z : std_logic;
    signal alu_fn : std_logic_vector (3 downto 0);
    -- RF
    signal rf_din, rf_dout_a, rf_dout_b : std_logic_vector (31 downto 0);
    signal rf_we : std_logic;
    signal rf_addr_w : std_logic_vector (4 downto 0);
    -- inmediato
    signal imm_val, imm_i, imm_s, imm_b, imm_u, imm_j : std_logic_vector (31 downto 0);
    -- fn_alu
    signal alu_fn_i : std_logic_vector (3 downto 0);
    signal alu_fn_r : std_logic_vector (3 downto 0);
    signal alu_fn_b : std_logic_vector (3 downto 0);

begin
    U1 : entity control port map (
        clk => clk,
        nreset => nreset,
        take_branch => take_branch,
        op => ir(6 downto 0),
        jump => jump,
        s1pc => s1pc,
        wpc => wpc,
        wmem => wmem,
        wreg => wreg,
        sel_imm => sel_imm,
        data_addr => data_addr,
        mem_source => mem_source,
        imm_source => imm_source,
        winst => winst,
        alu_mode => alu_mode,
        imm_mode => imm_mode
    );
    
    rf_addr_w <= ir(11 downto 7);
    -- x0 solo lectura
    rf_we <= wreg and (or rf_addr_w);
    pc_plus4 <= std_logic_vector(unsigned(pc) + 4);
    rf_din <= bus_dsm when mem_source = '1' else 
              imm_val when imm_source = '1' else 
              pc_plus4 when jump = '1' else
              alu_y;

    U2 : entity registro_32x32 port map(
        clk => clk,
        addr_1 => ir (19 downto 15),
        dout_1 => rf_dout_a,
        addr_2 => ir (24 downto 20),
        dout_2 => rf_dout_b,
        we_w   => rf_we,
        addr_w => rf_addr_w,
        din_w => rf_din
    );

    alu_a <= pc when s1pc = '1' else rf_dout_a;
    alu_b <= imm_val when sel_imm = '1' else rf_dout_b;
    
    U3 : entity alu 
        generic map( W => 32)
        port map (
        A => alu_a,
        B => alu_b,
        sel_fn => alu_fn,
        Y => alu_y,
        Z => alu_z
    );

    registros : process (clk)
    begin
        if rising_edge(clk) then
            if nreset = '0' then
                pc <= (others=>'0');
                ir <= (others => '0');
            elsif wpc = '1' then
                pc <= pc_next;
            end if;
            if winst = '1' then
                ir <= bus_dsm;
            end if;
        end if;
    end process;
   
    pc_next <= std_logic_vector(unsigned(pc) + unsigned(imm_val)) when
               (jump = '1' and ir(6 downto 0) = "1100011") else
               alu_y when jump = '1' else
               pc_plus4;   

    -- Bus del sistema
    bus_addr <= alu_y when data_addr = '1' else pc;
    bus_dms <= rf_dout_b;
    bus_twidth <= ir(14 downto 12) when data_addr = '1'else "010";
    bus_tms <= wmem;

    -- bloque de valor inmediato 
    with imm_mode select imm_val <=
                32x"4" when "000",
                imm_i  when "001",
                imm_s  when "010",
                imm_b  when "011",
                imm_u  when "100",
                imm_j  when others; -- "101"
    imm_i <= (31 downto 11 => ir(31)) & ir(30 downto 20);
    imm_s <= (31 downto 11 => ir(31)) & ir(30 downto 25) & ir(11 downto 7);
    imm_b <= (31 downto 12 => ir(31)) & ir(7) & ir(30 downto 25) & ir(11 downto 8) & "0";
    imm_u <= ir(31 downto 12) & (11 downto 0 => '0');
    imm_j <= (31 downto 20 => ir(31)) & ir(19 downto 12) & ir(20) & ir(30 downto 21) & "0";

    -- Función ALU, funct3 es ir(14 downto 12) y funct7(5) es ir(30)
    with alu_mode select alu_fn <=
                alu_fn_i when "01",
                alu_fn_r when "10",
                alu_fn_b when "11",
                "0000" when others; -- "00"
    alu_fn_i <= ir(14 downto 12) & (ir(30) and ir(12));
    alu_fn_r <= ir(14 downto 12) & ir(30);
    alu_fn_b <= "0" & ir(14 downto 13) & "1";

    -- Evaluación de condición para salto condicional en función de la bandera
    -- cero de la alu, para cada caso, en función de funct3
    with ir(14 downto 12) select take_branch <=
                alu_z when "000" | "101" | "111", -- igual, mayor o igual (el resultado cero es afirmativo)
                not alu_z when others; -- distinto, menor (el resultado cero es negativo)

end arch ; 