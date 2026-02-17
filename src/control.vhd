library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
    port (
        clk : in std_logic;
        nreset : in std_logic;
        take_branch : in std_logic; --señal que viene de la alu (Z)
        op : in std_logic_vector (6 downto 0); 
        jump : out std_logic; --selector del mux del PC 
        s1pc : out std_logic; --selector de la entrada A de la alu
        wpc : out std_logic; --habilita la escritura en PC 
        wmem : out std_logic; --habilita la escritura en memoria
        wreg : out std_logic; --habilita la escritura en registro
        sel_imm : out std_logic; --=0 la alu recibe RD2 y =1 recibe numero imm
        data_addr : out std_logic; 
        mem_source : out std_logic; 
        imm_source : out std_logic;
        winst : out std_logic; --habilita escritura en IR
        alu_mode : out std_logic_vector (1 downto 0);
        imm_mode : out std_logic_vector (2 downto 0)
    );
end control;

architecture arch of control is
    type estado_t is (
        INICIO,
        LEE_MEM_PC,
        CARGA_IR,
        DECODIFICA,
        LEE_MEM_DAT_INC_PC, --usado para LOAD 
        CARGA_RD_DE_MEM, 
        EJECUTA_R, --para sumas/restas con registros
        EJECUTA_I, --para inmediatos 
        CALC_ADDR_STORE, --calcular direccion para store
        ESCRIBE_MEM_STORE, --escribir en ram
        EVAL_BRANCH, --evaluar saltos
        EJECUTA_JAL, --salto incondicional
        EJECUTA_LUI, -- Tipo U (lui)
        EJECUTA_AUIPC, --tipo U (lui)
        EJECUTA_JALR --Tipo I de salto (jalr)
    );
    signal estado_sig, estado_act : estado_t;

    subtype imm_mode_t is std_logic_vector (2 downto 0);
    constant IMM_CONST_4 : imm_mode_t := "000";
    constant IMM_I : imm_mode_t := "001";
    constant IMM_S : imm_mode_t := "010";
    constant IMM_B : imm_mode_t := "011";
    constant IMM_U : imm_mode_t := "100";
    constant IMM_J : imm_mode_t := "101";
begin
    registros : process (clk)
    begin
        if rising_edge(clk) then
            if nreset = '0'  then
                estado_act <= INICIO;
            else
                estado_act <= estado_sig;
            end if ;
        end if;
    end process;

    logica_estado_sig : process(all)
    begin
        estado_sig <= INICIO;
        
        case( estado_act ) is
        
            when INICIO =>
                estado_sig <= LEE_MEM_PC;
            when LEE_MEM_PC => 
                estado_sig <= CARGA_IR;
            when CARGA_IR =>
                estado_sig <= DECODIFICA;
            when DECODIFICA => 
                case( op ) is
                    when "0000011" => --load
                         estado_sig <= LEE_MEM_DAT_INC_PC;

                    when "0010011" => --inmediatos
                         estado_sig <= EJECUTA_I;
                    
                    when "0100011" => --store 
                         estado_sig <= CALC_ADDR_STORE;

                    when "0110011" => --tipo R
                         estado_sig <= EJECUTA_R;

                    when "1100011" => --brach 
                         estado_sig <= EVAL_BRANCH;
                    
                    when "0110111" => --cargar inmediato superior 
                         estado_sig <= EJECUTA_LUI;
                    
                    when "0010111" => --sumar inmediato superior
                         estado_sig <= EJECUTA_AUIPC;

                    when "1101111" => 
                         estado_sig <= EJECUTA_JAL;

                    when "1100111" => --salto de registro
                         estado_sig <= EJECUTA_JALR;
                
                    when others => 
                         estado_sig <= INICIO;
                end case ;
            
            when LEE_MEM_DAT_INC_PC => 
                 estado_sig <= CARGA_RD_DE_MEM;
            
            when CARGA_RD_DE_MEM => 
                 estado_sig <= LEE_MEM_PC; --fin load

            when CALC_ADDR_STORE => 
                 estado_sig <= ESCRIBE_MEM_STORE;

            when ESCRIBE_MEM_STORE => 
                 estado_sig <= LEE_MEM_PC; --fin store

            when EJECUTA_R =>
                 estado_sig <= LEE_MEM_PC;

            when EJECUTA_I =>
                 estado_sig <= LEE_MEM_PC;

            when EVAL_BRANCH =>
                 estado_sig <= LEE_MEM_PC;

            when EJECUTA_LUI =>
                 estado_sig <= LEE_MEM_PC;

            when EJECUTA_AUIPC =>
                 estado_sig <= LEE_MEM_PC;
            
            when EJECUTA_JAL =>
                 estado_sig <= LEE_MEM_PC;
            
            when EJECUTA_JALR =>
                 estado_sig <= LEE_MEM_PC;

            when others =>
                 estado_sig <= INICIO;
        end case ;
    end process;

    logica_salida : process (all)
    begin
        wpc <= '0';
        wmem <= '0';
        winst <= '0';
        wreg <= '0';
        jump <= '0';
        s1pc <= '0';
        alu_mode <= "00";
        imm_mode <= IMM_CONST_4;
        sel_imm <= '0';
        data_addr <= '0';
        mem_source <= '0';
        imm_source <= '0';

        case( estado_act ) is
        
            when INICIO =>
                
            when LEE_MEM_PC => 
                 data_addr <= '0';
            
            when CARGA_IR => 
                 winst <= '1';
                
            when DECODIFICA => 

            when LEE_MEM_DAT_INC_PC => 
                 alu_mode <= "00";
                 sel_imm <= '1';
                 imm_mode <= IMM_I;
                 data_addr <= '1';
                 wpc <= '1';
            
            when CARGA_RD_DE_MEM => 
                 alu_mode <= "00";
                 sel_imm <= '1';
                 imm_mode <= IMM_I;
                 data_addr <= '1';

                 mem_source <= '1';
                 wreg <= '1';

            when CALC_ADDR_STORE => 
                 alu_mode <= "00";
                 sel_imm <= '1';
                 imm_mode <= IMM_S;
                 wpc <= '1';

            when ESCRIBE_MEM_STORE => 
                 alu_mode <= "00";
                 sel_imm <= '1';
                 imm_mode <= IMM_S;

                 data_addr <= '1';
                 wmem <= '1';
            
            when EJECUTA_R =>
                 alu_mode <= "10";
                 sel_imm <= '0';
                 wreg <= '1';
                 wpc <= '1';

            when EJECUTA_I => 
                 alu_mode <= "01";
                 sel_imm <= '1';
                 imm_mode <= IMM_I;
                 wreg <= '1';
                 wpc <= '1';
            
            when EVAL_BRANCH =>
                 alu_mode <= "11";
                 sel_imm <= '0';
                 imm_mode <= IMM_B;
                 wpc <= '1';
                 if take_branch = '1' then
                    jump <= '1';
                 else 
                    jump <= '0';
                 end if ;
            
            when EJECUTA_LUI => 
                 alu_mode <= "00";
                 s1pc <= '0';
                 sel_imm <= '1';
                 imm_mode <= IMM_U;
                 imm_source <= '1';
                 wreg <= '1';
                 wpc <= '1';

            when EJECUTA_AUIPC => 
                 alu_mode <= "00";
                 s1pc <= '1';
                 sel_imm <= '1';
                 imm_mode <= IMM_U;
                 wreg <= '1';
                 wpc <= '1';

            when EJECUTA_JAL => 
                 s1pc <= '1';
                 sel_imm <= '1';
                 imm_mode <= IMM_J;
                 jump <= '1';
                 wpc <= '1';
                 wreg <= '1';

            when EJECUTA_JALR =>
                 s1pc <= '0';
                 sel_imm <= '1';
                 imm_mode <= IMM_I;
                 jump <= '1';
                 wpc <= '1';
                 wreg <= '1';
        
            when others =>
        end case ;
    end process;
end arch ; -- arch
