function build_pcode(varargin)
% build_pcode  Genera un paquete de distribucion en matlab/dist/ con el
%   codigo ofuscado (pcode) mas los archivos que sí necesita quien reciba
%   el paquete para construir y correr el modelo.
%
%   No modifica ni borra los .m originales: estos siguen siendo la
%   fuente de verdad en el repositorio. El paquete de dist/ es un
%   subproducto de build, pensado para entregar a terceros sin exponer
%   ThermalPlantInterface.m en claro.
%
%   Contenido de matlab/dist/ tras ejecutar esto:
%     - ThermalPlantInterface.p   (ofuscado, sin el .m)
%     - build_thermal_model.m     (copiado tal cual, código no sensible)
%
%   El bloque MATLAB System de Simulink (y build_thermal_model, que lo
%   referencia por nombre 'ThermalPlantInterface') resuelve el .p de
%   forma transparente si esa carpeta esta en el path: no hace falta
%   tocar el modelo ni el script.
%
%   Nota: pcode NO es cifrado fuerte, solo ofuscacion (bytecode de
%   MATLAB). No lo uses como unica proteccion si el codigo es sensible.
%
%   Uso:
%       build_pcode
%       build_pcode('ThermalPlantInterface.m')   % archivos a ofuscar

    if isempty(varargin)
        filesToObfuscate = {'ThermalPlantInterface.m'};
    else
        filesToObfuscate = varargin;
    end

    % Archivos que se copian sin ofuscar porque quien recibe el paquete
    % los necesita para construir/ejecutar el modelo.
    filesToCopyPlain = {'build_thermal_model.m'};

    srcDir = fileparts(mfilename('fullpath'));
    outDir = fullfile(srcDir, 'dist');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % pcode no soporta '-outdir': escribe siempre en el directorio actual.
    % Nos movemos temporalmente a outDir y le pasamos la ruta absoluta
    % del .m de origen.
    oldDir = pwd;
    cd(outDir);
    try
        for i = 1:numel(filesToObfuscate)
            pcode(fullfile(srcDir, filesToObfuscate{i}));
            fprintf('Ofuscado: %s\n', fullfile(outDir, strrep(filesToObfuscate{i}, '.m', '.p')));
        end
    catch ME
        cd(oldDir);
        rethrow(ME);
    end
    cd(oldDir);

    for i = 1:numel(filesToCopyPlain)
        copyfile(fullfile(srcDir, filesToCopyPlain{i}), outDir);
        fprintf('Copiado:  %s\n', fullfile(outDir, filesToCopyPlain{i}));
    end

    fprintf('\nPaquete de distribucion listo en: %s\n', outDir);
    fprintf('Entregalo entero; quien lo reciba solo tiene que anadirlo al path de MATLAB y ejecutar build_thermal_model.\n');
end
