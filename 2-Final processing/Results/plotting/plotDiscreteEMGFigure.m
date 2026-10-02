function plotDiscreteEMGFigure(disc, stats, PARAMS, PARAM_LABELS, EMG_LABELS, MUSCLE_DISPLAY, ...
                               COND_LABELS, COLORS, pairIdx)
% =========================================================================
% plotDiscreteEMGFigure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Supplementary figure of the discrete EMG parameters
%                (extract_emg_discrete_all_comp.m) : grid parameter (rows)
%                x muscle (columns). Each panel shows, per condition, every
%                patient's value (grey dots, joined across conditions by
%                thin lines so within-subject changes are visible) and the
%                group mean ± SD (coloured marker + error bar). Pairs
%                significant after Holm-Bonferroni (paired t-test,
%                significant RM-ANOVA) are marked by brackets with stars,
%                packed on as few levels as possible. The RM-ANOVA p-value
%                is given in each panel title.
%                The manuscript version (one muscle, selected parameters)
%                is plotDiscreteEMGManuscript.m.
% -------------------------------------------------------------------------
% Parameters :   disc        — struct, disc.(param) = (nPat, nCond, nMus)
%                stats       — struct array (1 x nMus), stats(im).(param)
%                              .anova_p / .anova_sig / .sig / .pHolm
%                PARAMS, PARAM_LABELS — tested parameter names / labels
%                EMG_LABELS, MUSCLE_DISPLAY — muscle names / display map
%                COND_LABELS, COLORS — condition labels / colours
%                pairIdx     — (nPairs x 2) condition indices of each pair
% Outputs    :   1 figure
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

FONT  = 'Times New Roman';
nMus  = numel(EMG_LABELS);
nPar  = numel(PARAMS);
nCond = numel(COND_LABELS);

figure('Name', 'EMG discrete parameters -- all pairwise comparisons', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');

for k = 1:nPar
    for im = 1:nMus
        ax = subplot(nPar, nMus, (k-1)*nMus + im); hold on;
        Y  = disc.(PARAMS{k})(:, :, im);     % (nPat, nCond)
        st = stats(im).(PARAMS{k});

        % trajectoires individuelles
        for ip = 1:size(Y, 1)
            plot(1:nCond, Y(ip, :), '-', 'Color', [0.80 0.80 0.80], 'LineWidth', 0.5);
            plot(1:nCond, Y(ip, :), '.', 'Color', [0.55 0.55 0.55], 'MarkerSize', 7);
        end
        % moyenne ± ET
        mu = mean(Y, 1, 'omitnan'); sd = std(Y, 0, 1, 'omitnan');
        for ic = 1:nCond
            errorbar(ic, mu(ic), sd(ic), 'o', 'Color', COLORS(ic,:), 'MarkerFaceColor', COLORS(ic,:), ...
                     'MarkerSize', 6, 'LineWidth', 1.4, 'CapSize', 4);
        end

        yTop = max([Y; mu + sd], [], 1, 'omitnan');
        yl   = [min([Y(:); (mu - sd)'], [], 'omitnan'), max(yTop)];
        if any(~isfinite(yl)) || yl(2) <= yl(1), yl = [0 1]; end
        rngY = yl(2) - yl(1);

        % crochets + etoiles (paires Holm-significatives, ANOVA significative)
        nLev = 0;
        if st.anova_sig && any(st.sig)
            nLev = drawSigBrackets(pairIdx(st.sig, :), st.pHolm(st.sig), yl(2), rngY, FONT, 9);
        end
        ylim([yl(1) - 0.05*rngY, yl(2) + (0.08 + 0.14*nLev)*rngY]);
        xlim([0.5 nCond + 0.5]);
        ax.YAxis.Exponent = 0;               % pas de facteur x10^n cache par la ligne du dessus
        yt = ax.YTick;                       % pas de graduation dans la zone des crochets
        ax.YTick = yt(yt <= yl(2) + 0.02*rngY);
        ytickformat(ax, '%g');

        if k == 1
            title({MUSCLE_DISPLAY(EMG_LABELS{im}), sprintf('ANOVA p %s', pStr(st.anova_p))}, ...
                  'FontName', FONT, 'FontSize', 11, 'FontWeight', 'normal');
        else
            title(sprintf('ANOVA p %s', pStr(st.anova_p)), 'FontName', FONT, 'FontSize', 9, 'FontWeight', 'normal');
        end
        set(ax, 'XTick', 1:nCond, 'FontName', FONT, 'FontSize', 8);
        if k == nPar
            set(ax, 'XTickLabel', COND_LABELS, 'XTickLabelRotation', 40);
        else
            set(ax, 'XTickLabel', []);
        end
        if im == 1, ylabel(PARAM_LABELS{k}, 'FontName', FONT, 'FontSize', 9); end
        grid on; box on; hold off;
    end
end

sgtitle('EMG discrete parameters (mean ± SD; grey: individual participants; * Holm-Bonferroni-corrected pairwise differences)', ...
        'FontName', FONT, 'FontSize', 12);
end


function s = pStr(p)
    if isnan(p), s = '= n/a'; elseif p < 0.001, s = '< 0.001'; else, s = sprintf('= %.3f', p); end
end


function nLevels = drawSigBrackets(sigPairs, pHolm, yBase, rngY, FONT, fontSize)
    % Crochets + etoiles des paires Holm-significatives. Les crochets sont
    % ranges sur des niveaux compacts : du plus court au plus long, chacun
    % sur le niveau le plus bas ou il ne chevauche aucun autre crochet.
    nLevels = 0;
    if isempty(sigPairs), return; end
    [~, ord] = sort(sigPairs(:,2) - sigPairs(:,1));
    levelSpans = {};                      % levelSpans{l} = (n x 2) intervalles occupes
    for s = ord'
        a = sigPairs(s,1); b = sigPairs(s,2);
        lvl = 1;
        while lvl <= numel(levelSpans) && any(levelSpans{lvl}(:,1) <= b & levelSpans{lvl}(:,2) >= a)
            lvl = lvl + 1;
        end
        if lvl > numel(levelSpans), levelSpans{lvl} = zeros(0,2); end
        levelSpans{lvl}(end+1,:) = [a b];
        yb = yBase + rngY * (0.06 + 0.14 * (lvl-1));
        plot([a a b b], [yb - rngY*0.025, yb, yb, yb - rngY*0.025], 'k-', 'LineWidth', 0.8);
        % etoiles centrees SUR le trait, fond blanc : elles interrompent leur
        % propre crochet au lieu de deborder sur le niveau du dessus
        text((a+b)/2, yb, starStr(pHolm(s)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', fontSize, ...
             'BackgroundColor', 'white', 'Margin', 0.5);
    end
    nLevels = numel(levelSpans);
end


function s = starStr(p)
    if p < 0.001, s = '***'; elseif p < 0.01, s = '**'; else, s = '*'; end
end
