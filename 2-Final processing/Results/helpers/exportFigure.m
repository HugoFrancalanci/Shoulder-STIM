function exportFigure(fig, baseName)
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
% Description : High-resolution export of an article figure, at a fixed size
%               so that the layout does not depend on the screen: TIFF at
%               600 dpi and vector PDF, in the Figures subfolder of the data
%               folder (helpers/dataDir.m).
% -------------------------------------------------------------------------
% Parameters  : fig      : figure handle
%               baseName : file name without extension (e.g. 'Figure_5')
% Outputs     : <dataDir>/Figures/<baseName>.tif and .pdf
% -------------------------------------------------------------------------
% Dependencies: helpers/dataDir.m
% =========================================================================

FIG_SIZE_PX = [1800 900];   % taille fixe (largeur, hauteur) en pixels
DPI = 600;

outDir = fullfile(dataDir(), 'Figures');
if ~isfolder(outDir), mkdir(outDir); end

fig.Units = 'pixels';
fig.Position = [0 0 FIG_SIZE_PX];
drawnow;
exportgraphics(fig, fullfile(outDir, [baseName '.tif']), 'Resolution', DPI);
exportgraphics(fig, fullfile(outDir, [baseName '.pdf']), 'ContentType', 'vector');
fprintf('Figure exportee : %s (.tif %d dpi, .pdf vectoriel)\n', fullfile(outDir, baseName), DPI);
end
