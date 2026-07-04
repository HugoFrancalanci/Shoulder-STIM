function [] = corridor(value,dimension,color)
hold on;
MEAN = nanmean(value,dimension);
STD  = nanstd(value,1,dimension);
n    = size(MEAN,1);
x    = [1:1:n n:-1:1]';
y    = [MEAN+STD;MEAN(end:-1:1)-STD(end:-1:1)]; % [Aller;Retour]
A    = fill(x,y,color,'LineStyle','none','FaceAlpha',0.2); % Trace le corridor +/- 1 SD
set(get(get(A,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Retire surface de la legende
plot(MEAN,'Linewidth',2,'Color',color);
