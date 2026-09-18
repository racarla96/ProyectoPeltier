classdef ThermalPlantInterface < matlab.System
    % ThermalPlantInterface  Bloque MATLAB System para Simulink.
    %   Envia la accion de control u a la RP2040 (protocolo "U,<u>\n")
    %   y devuelve las ultimas temperaturas recibidas (protocolo
    %   "T,<t_ms>,<T_amb>,<T_c>,<T_h>\n").
    %
    %   Entrada:  u      (double, escalar, se satura a [-1,1] aqui tambien)
    %   Salidas:  T_amb, T_c, T_h (double, escalares, en grados C)

    properties (Nontunable)
        Port     = "COM3"    % Cambiar al puerto serie de la RP2040
        BaudRate = 115200    % Irrelevante para USB-CDC nativo, pero requerido por serialport
    end

    properties (Access = private)
        SerialObj
        LastT = [21 21 21]
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.SerialObj = serialport(obj.Port, obj.BaudRate, "Timeout", 0.05);
            configureTerminator(obj.SerialObj, "LF");
            flush(obj.SerialObj);
        end

        function [T_amb, T_c, T_h] = outputImpl(obj, u)
            u = max(min(u, 1), -1);
            writeline(obj.SerialObj, sprintf("U,%.4f", u));

            % Vaciar buffer y quedarnos con la ultima linea valida disponible
            % (evita acumular retardo si Simulink corre mas lento que 100 Hz)
            while obj.SerialObj.NumBytesAvailable > 0
                try
                    line = readline(obj.SerialObj);
                catch
                    break
                end
                parts = split(strtrim(line), ",");
                if numel(parts) == 5 && strcmp(parts(1), "T")
                    Tamb_ = str2double(parts(3));
                    Tc_   = str2double(parts(4));
                    Th_   = str2double(parts(5));
                    if ~any(isnan([Tamb_ Tc_ Th_]))
                        obj.LastT = [Tamb_, Tc_, Th_];
                    end
                end
            end

            T_amb = obj.LastT(1);
            T_c   = obj.LastT(2);
            T_h   = obj.LastT(3);
        end

        function releaseImpl(obj)
            if ~isempty(obj.SerialObj)
                clear obj.SerialObj;
            end
        end

        function num = getNumInputsImpl(~)
            num = 1;
        end

        function num = getNumOutputsImpl(~)
            num = 3;
        end

        function [n1, n2, n3] = getOutputSizeImpl(~)
            n1 = 1; n2 = 1; n3 = 1;
        end

        function [f1, f2, f3] = isOutputFixedSizeImpl(~)
            f1 = true; f2 = true; f3 = true;
        end

        function [d1, d2, d3] = getOutputDataTypeImpl(~)
            d1 = 'double'; d2 = 'double'; d3 = 'double';
        end

        function [c1, c2, c3] = isOutputComplexImpl(~)
            c1 = false; c2 = false; c3 = false;
        end

        function sts = getSampleTimeImpl(obj)
            % Discreto a 100 Hz, igual que la planta en la RP2040
            sts = createSampleTime(obj, 'Type', 'Discrete', 'SampleTime', 0.01);
        end
    end
end
