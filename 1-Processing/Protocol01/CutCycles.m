% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   June 2022
% -------------------------------------------------------------------------
% Description:   To be defined
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [Trial, threshold] = CutCycles(c3dFiles,Trial,btype,side,threshold)

% Initialisation
disp('  - Découpage des cycles de mouvement');
Rcycles = [];
Lcycles = [];

if contains(c3dFiles.name,'ANALYTIC') || contains(c3dFiles.name,'FUNCTIONAL')
    % Set cycles — signal sélectionné selon le côté opéré
    start = [];
    stop = [];
    value = [];
    % Joint index : 1 = droit, 6 = gauche
    if strcmpi(side, 'R')
        jIdx = 1;
    else
        jIdx = 6;
    end
    if contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL3')
        value = abs(squeeze(Trial.Joint(jIdx).Euler.full(:,1,:))');
    elseif contains(c3dFiles.name,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2')
        value = abs(squeeze(Trial.Joint(jIdx).Euler.full(:,3,:))');
    elseif contains(c3dFiles.name,'ANALYTIC3') || contains(c3dFiles.name,'FUNCTIONAL4')
        value = -squeeze(Trial.Joint(jIdx).Euler.full(:,2,:))';
    elseif contains(c3dFiles.name,'ANALYTIC4')
        value = squeeze(Trial.Joint(jIdx).Euler.full(:,2,:))';
    end
    if ~isempty(value)
        value = unwrap(value);
        if strcmpi(side, 'R')
            % Côté choisi (droit) : détection automatique par seuillage
            [Rcycles, threshold] = detectCycles(value, c3dFiles.name, 'Droit', threshold);
            % Côté non choisi (gauche) : copie des ranges
            for icycle = 1:size(Rcycles,2)
                Lcycles(icycle).range = Rcycles(icycle).range;
            end
        else
            % Côté choisi (gauche) : détection automatique par seuillage
            [Lcycles, threshold] = detectCycles(value, c3dFiles.name, 'Gauche', threshold);
            % Côté non choisi (droit) : copie des ranges
            for icycle = 1:size(Lcycles,2)
                Rcycles(icycle).range = Lcycles(icycle).range;
            end
        end
    end

    % Cut cycles
    % Cycle
    Trial.Rcycle = Rcycles;
    Trial.Lcycle = Lcycles;
    % Markers
    for imarker = 1:size(Trial.Marker,2)
        % Right side
        if ~isempty(Rcycles)
            for icycle = 1:size(Rcycles,2)
                n  = size(Rcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isnan(sum(Trial.Marker(imarker).Trajectory.full(1,1,:)))
                    Trial.Marker(imarker).Trajectory.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Marker(imarker).Trajectory.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                    
                else
                    Trial.Marker(imarker).Trajectory.rcycle(:,:,:,icycle) = nan(3,1,101,1);
                end
            end
        end
        % Left side
        if ~isempty(Lcycles)
            for icycle = 1:size(Lcycles,2)
                n  = size(Lcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isnan(sum(Trial.Marker(imarker).Trajectory.full(1,1,:)))
                    Trial.Marker(imarker).Trajectory.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Marker(imarker).Trajectory.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Marker(imarker).Trajectory.lcycle(:,:,:,icycle) = nan(3,1,101,1);
                end
            end
        end
    end
    % Vmarkers
    for ivmarker = 1:size(Trial.Vmarker,2)
        % Right side
        if ~isempty(Rcycles)
            for icycle = 1:size(Rcycles,2)
                n  = size(Rcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Vmarker(ivmarker).Trajectory.full)
                    Trial.Vmarker(ivmarker).Trajectory.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Vmarker(ivmarker).Trajectory.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                end
            end
        end
        % Left side
        if ~isempty(Lcycles)
            for icycle = 1:size(Lcycles,2)
                n  = size(Lcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Vmarker(ivmarker).Trajectory.full)
                    Trial.Vmarker(ivmarker).Trajectory.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Vmarker(ivmarker).Trajectory.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                end
            end
        end
    end
    % Segments
    for isegment = 1:size(Trial.Segment,2)
        % Right side
        if ~isempty(Rcycles)
            for icycle = 1:size(Rcycles,2)
                n  = size(Rcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Segment(isegment).rM.full)
                    Trial.Segment(isegment).rM.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).rM.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).rM.rcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).Q.full)
                    Trial.Segment(isegment).Q.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).Q.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).Q.rcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).T.full)
                    Trial.Segment(isegment).T.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).T.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).T.rcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).Euler.full)
                    Trial.Segment(isegment).Euler.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).Euler.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).Euler.rcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).dj.full)
                    Trial.Segment(isegment).dj.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).dj.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).dj.rcycle = [];
                end
            end
        end
        % Left side
        if ~isempty(Lcycles)
            for icycle = 1:size(Lcycles,2)
                n  = size(Lcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Segment(isegment).rM.full)
                    Trial.Segment(isegment).rM.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).rM.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).rM.lcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).Q.full)
                    Trial.Segment(isegment).Q.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).Q.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).Q.lcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).T.full)
                    Trial.Segment(isegment).T.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).T.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).T.lcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).Euler.full)
                    Trial.Segment(isegment).Euler.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).Euler.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).Euler.lcycle = [];
                end
                if ~isempty(Trial.Segment(isegment).dj.full)
                    Trial.Segment(isegment).dj.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Segment(isegment).dj.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Segment(isegment).dj.lcycle = [];
                end
            end
        end
    end
    % Joints
    for ijoint = 1:size(Trial.Joint,2)
        % Right side
        if ~isempty(Rcycles)
            for icycle = 1:size(Rcycles,2)
                n  = size(Rcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Joint(ijoint).T.full)
                    Trial.Joint(ijoint).T.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).T.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Joint(ijoint).T.rcycle = [];
                end
                if ~isempty(Trial.Joint(ijoint).Euler.full)
                    Trial.Joint(ijoint).Euler.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).Euler.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                    if ijoint == 1 || ijoint == 6
                        if ~isempty(Trial.Joint(ijoint).ElevationPlane.full)
                            Trial.Joint(ijoint).ElevationPlane.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).ElevationPlane.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                        else
                            Trial.Joint(ijoint).ElevationPlane.rcycle = [];
                        end
                    end
                else
                    Trial.Joint(ijoint).Euler.rcycle = [];
                    Trial.Joint(ijoint).ElevationPlane.rcycle = [];
                end
                if ~isempty(Trial.Joint(ijoint).dj.full)
                    Trial.Joint(ijoint).dj.rcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).dj.full(:,:,Rcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Joint(ijoint).dj.rcycle = [];
                end
            end
        end
        % Left side
        if ~isempty(Lcycles)
            for icycle = 1:size(Lcycles,2)
                n  = size(Lcycles(icycle).range,1);
                k0 = (1:n)';
                k1 = (linspace(1,n,101))';
                if ~isempty(Trial.Joint(ijoint).T.full)
                    Trial.Joint(ijoint).T.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).T.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Joint(ijoint).T.lcycle = [];
                end
                if ~isempty(Trial.Joint(ijoint).Euler.full)
                    Trial.Joint(ijoint).Euler.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).Euler.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                    if ijoint == 1 || ijoint == 6
                        if ~isempty(Trial.Joint(ijoint).ElevationPlane.full)
                            Trial.Joint(ijoint).ElevationPlane.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).ElevationPlane.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                        else
                            Trial.Joint(ijoint).ElevationPlane.lcycle = [];
                        end
                    end
                else
                    Trial.Joint(ijoint).Euler.lcycle = [];
                    Trial.Joint(ijoint).ElevationPlane.lcycle = [];
                end
                if ~isempty(Trial.Joint(ijoint).dj.full)
                    Trial.Joint(ijoint).dj.lcycle(:,:,:,icycle) = permute(interp1(k0,permute(Trial.Joint(ijoint).dj.full(:,:,Lcycles(icycle).range),[3,1,2]),k1,'spline'),[2,3,1]);
                else
                    Trial.Joint(ijoint).dj.lcycle = [];
                end
            end
        end
    end
    % Emg
    % Traitement simplifié : baseline = 50 premières frames marker, enveloppe calée sur cycles cinématiques
    fratio = Trial.fanalog / Trial.fmarker;
    if ~isempty(Trial.Emg)
        for iemg = 1:size(Trial.Emg,2)
            if ~isempty(Trial.Emg(iemg).Signal.full)

                % Prétraitement : suppression outliers, passe-bande, rectification
                signal0 = filloutliers(squeeze(Trial.Emg(iemg).Signal.full), 'nearest', 'mean', ThresholdFactor=5);
                [B,A]   = butter(1, [10 500]./(Trial.fanalog/2), 'bandpass');
                signal  = filtfilt(B, A, signal0);
                signal  = abs(signal);

                % Enveloppe RMS 
                envelop  = interpft(rms2(signal, 0.02*Trial.fanalog, 0.01*Trial.fanalog, 1), length(signal));
                % Enveloppe lissée gaussienne (pour découpage et affichage magenta)
                envelop2 = smoothdata(envelop, 'gaussian', round(0.1*Trial.fanalog))';

                % Normalisation par la baseline (50 premières frames cinématiques)
                baselineEnd  = min(50 * round(fratio), length(signal));
                baseline     = signal(1:baselineEnd);
                normFactor   = mean(baseline) + 3*std(baseline);
                if normFactor > 0
                    envelop_norm = envelop2 / normFactor;
                else
                    envelop_norm = envelop2;
                end

                % Stockage de l'enveloppe complète normalisée
                Trial.Emg(iemg).Signal.envelop(:,:,:) = permute(envelop_norm, [2,3,1]);

                % Sélection du côté
                if strcmpi(side, 'R')
                    activeCycles = Rcycles;
                else
                    activeCycles = Lcycles;
                end

                % Visualisation de vérification
                ylimit = 4e-4;
                fig = figure('units','normalized','outerposition',[0 0 1 1]);
                hold on;
                ylim([-ylimit ylimit]);
                title([Trial.Emg(iemg).label, '  —  ', c3dFiles.name], 'Interpreter', 'none');
                plot(signal0, 'Color', [0.5 0.5 0.5]);           % Signal brut (gris)
                plot(signal,  'Color', 'blue');                   % Signal filtré rectifié (bleu)
                plot(envelop, 'Color', 'green');                  % Enveloppe RMS (vert)
                plot(envelop2,'Color', 'magenta', 'LineWidth', 2);% Enveloppe lissée (magenta)
                line([1 length(signal)], [normFactor normFactor], 'Color', 'red', 'LineStyle', '-'); % Seuil baseline
                if ~isempty(activeCycles)
                    for icycle = 1:size(activeCycles,2)
                        istart = max(round(activeCycles(icycle).range(1)   * fratio), 1);
                        iend   = min(round(activeCycles(icycle).range(end) * fratio), length(signal));
                        rectangle('Position', [istart 0 iend-istart max(signal0)], ...
                                  'FaceColor', [0 1 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                    end
                end
                disp(['  [EMG] ' Trial.Emg(iemg).label ' — Appuyer sur Entrée pour continuer.']);
                input('', 's');
                close(fig);

                % Découpage sur les cycles cinématiques (côté choisi)
                % Chaque étape du pipeline est stockée séparément
                if ~isempty(activeCycles)
                    for icycle = 1:size(activeCycles,2)
                        istart = round(activeCycles(icycle).range(1)   * fratio);
                        iend   = round(activeCycles(icycle).range(end) * fratio);
                        istart = max(istart, 1);
                        iend   = min(iend, length(signal0));
                        n      = iend - istart + 1;
                        if n >= 2
                            k0 = (1:n)';
                            k1 = linspace(1,n,101)';
                            % 1 - Signal brut (outliers supprimés)
                            Trial.Emg(iemg).Signal.cycle.raw(:,:,:,icycle)        = permute(interp1(k0, signal0(istart:iend),        k1, 'spline'), [2,3,1]);
                            % 2 - Signal filtré (passe-bande 10-500 Hz)
                            sig_filt = filtfilt(B, A, signal0);
                            Trial.Emg(iemg).Signal.cycle.filtered(:,:,:,icycle)   = permute(interp1(k0, sig_filt(istart:iend),       k1, 'spline'), [2,3,1]);
                            % 3 - Signal rectifié
                            Trial.Emg(iemg).Signal.cycle.rectified(:,:,:,icycle)  = permute(interp1(k0, signal(istart:iend),         k1, 'spline'), [2,3,1]);
                            % 4 - Enveloppe RMS
                            Trial.Emg(iemg).Signal.cycle.rms(:,:,:,icycle)        = permute(interp1(k0, envelop(istart:iend),        k1, 'spline'), [2,3,1]);
                            % 5 - Enveloppe lissée gaussienne
                            Trial.Emg(iemg).Signal.cycle.envelop(:,:,:,icycle)    = permute(interp1(k0, envelop2(istart:iend),       k1, 'spline'), [2,3,1]);
                            % 6 - Enveloppe normalisée par baseline
                            Trial.Emg(iemg).Signal.cycle.normalized(:,:,:,icycle) = permute(interp1(k0, envelop_norm(istart:iend)',  k1, 'spline'), [2,3,1]);
                        else
                            Trial.Emg(iemg).Signal.cycle.raw(:,:,:,icycle)        = NaN(1,1,101);
                            Trial.Emg(iemg).Signal.cycle.filtered(:,:,:,icycle)   = NaN(1,1,101);
                            Trial.Emg(iemg).Signal.cycle.rectified(:,:,:,icycle)  = NaN(1,1,101);
                            Trial.Emg(iemg).Signal.cycle.rms(:,:,:,icycle)        = NaN(1,1,101);
                            Trial.Emg(iemg).Signal.cycle.envelop(:,:,:,icycle)    = NaN(1,1,101);
                            Trial.Emg(iemg).Signal.cycle.normalized(:,:,:,icycle) = NaN(1,1,101);
                        end
                    end
                end

            end
        end
    end

    % Export cycles
    Trial.Rcycle = Rcycles;
    Trial.Lcycle = Lcycles;
end
