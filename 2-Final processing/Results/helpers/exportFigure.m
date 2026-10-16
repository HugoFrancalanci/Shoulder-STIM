function exportFigure(fig, baseName, outDir)
% =========================================================================
% exportFigure.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : High-resolution export of an article figure at a fixed paper
%               size (18.75 x 9.375 in), so that the layout depends neither on
%               the screen size nor on the MATLAB theme: PNG at 600 dpi
%               (lossless, < 10 MB) and vector PDF, in the Figures subfolder of the
%               data folder (helpers/dataDir.m) unless outDir is given.
% -------------------------------------------------------------------------
% Parameters  : fig      : figure handle
%               baseName : file name without extension (e.g. 'Figure_5')
%               outDir   : (optional) output folder
% Outputs     : <outDir>/<baseName>.png and .pdf
% -------------------------------------------------------------------------
% Dependencies: helpers/dataDir.m
% =========================================================================

PAPER_IN = [18.75 9.375];   % taille fixe (largeur, hauteur) en pouces = 1800 x 900 px a 96 dpi
DPI = 600;

if nargin < 3, outDir = fullfile(dataDir(), 'Figures'); end
if ~isfolder(outDir), mkdir(outDir); end

if isprop(fig, 'Theme'), fig.Theme = 'light'; end   % pas de theme sombre (MATLAB R2025a+)
fig.PaperUnits = 'inches';
fig.PaperSize = PAPER_IN;
fig.PaperPositionMode = 'manual';
fig.PaperPosition = [0 0 PAPER_IN];
fig.InvertHardcopy = 'off';                           % garder le fond blanc tel quel
% PNG (compresse sans perte) plutot que TIFF : < 10 Mo par fichier, limite du journal
print(fig, fullfile(outDir, [baseName '.png']), '-dpng', sprintf('-r%d', DPI));
print(fig, fullfile(outDir, [baseName '.pdf']), '-dpdf', '-vector');
fprintf('Figure exportee : %s (.png %d dpi, .pdf vectoriel)\n', fullfile(outDir, baseName), DPI);
end
