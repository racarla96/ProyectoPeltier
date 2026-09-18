function build_pcode(varargin)
% build_pcode  Genera versiones .p (ofuscadas via MATLAB pcode) de los
%   archivos fuente que se quieran distribuir sin exponer el codigo en
%   claro (p.ej. para compartir el bloque de interfaz con la RP2040 sin
%   dar el .m legible).
%
%   Los .p resultantes se comportan igual que los .m originales: el
%   bloque MATLAB System de Simulink (y cualquier llamada que use
%   'ThermalPlantInterface') los resuelve automaticamente si estan en
%   el path, sin cambios en el modelo.
%
%   Nota: pcode NO es cifrado fuerte, solo ofuscacion (bytecode de
%   MATLAB). No lo uses como unica proteccion si el codigo es sensible.
%
%   Uso:
%       build_pcode
%       build_pcode('ThermalPlantInterface.m')

    if isempty(varargin)
        files = {'ThermalPlantInterface.m'};
    else
        files = varargin;
    end

    outDir = fullfile(fileparts(mfilename('fullpath')), 'pcode');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    for i = 1:numel(files)
        pcode(files{i}, '-outdir', outDir);
        fprintf('Generado: %s\n', fullfile(outDir, strrep(files{i}, '.m', '.p')));
    end

    fprintf('\nListos en: %s\n', outDir);
    fprintf('Para usarlos: anade esa carpeta al path de MATLAB (addpath) en vez de, o ademas de, la carpeta con los .m originales.\n');
end
