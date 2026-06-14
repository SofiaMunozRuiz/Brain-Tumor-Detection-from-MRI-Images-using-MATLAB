%% Electiva: Procesamiento de imagenes
%  Estudiante: Marlen Sofia Muñoz
%  Deteccion de tumores cerebrales con segmentacion im2bw.
clear all; clc;

% Segmentacion
a = imread('Te-no1.jpg');
a1 =rgb2gray(a);
um = im2bw(a1,0.35);
figure(1); imshow(um)


% Filtro Mediana
a_fm= medfilt2(um, 'zeros');
s = size(a);

% Filtro pasa alta para remover ruido
arc = a_fm*0;
kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1]/8;   % filtro de promedio- eliminando frecuencias altas

for i= 2:s(1)-1
    for j= 2:s(1)-1
        ventana = a_fm(i-1:i+1, j-1:j+1);
        producto = ventana .* kernel;
        pix = sum(sum(producto));   %f[x,y]*g[x,y]
        arc(i,j) = pix;
    
     end
end
alf = a_fm-arc;

% Calcular el funcionamiento morfológico.
BW1 = bwareaopen(alf,200);

BW2 = bwmorph(BW1,"fill",inf);
BW3 = bwmorph(BW2,"bridge",inf);
BW4 = bwmorph(BW3,"majority",inf);
BW5 = bwmorph(BW4,"close",inf);
BW6 = bwmorph(BW5,"clean",inf);
%BW7 = bwmorph(BW6,"remove",inf);


[L,N] = bwlabel(BW6);
cb= a+uint8(BW6);
figure; imshow(cb)

prop = regionprops(L,'all');
fields =  {'SubarrayIdx','ConvexHull','ConvexImage','Image','FilledImage','Extrema','PixelIdxList','PixelList'};
prop = rmfield(prop, fields);
hold on 

%Graficar los rectangulos
colors=['b' 'g' 'r' 'c' 'm' 'y'];
for n=1:size(prop,1)
    rectangle('Position',prop(n).BoundingBox,'EdgeColor','r','LineWidth',2);
    col =prop(n).BoundingBox(1);
    row =prop(n).BoundingBox(2);
    cidx = mod(n,length(colors))+1;
    h = text(col+1, row-1, num2str(n));
    set(h,'Color',colors(cidx),'FontSize',14,'FontWeight','bold');
end
pause(3)

% Extraccion de caracteristicas principales
diam = zeros(1,4);
radio = zeros(1,4);
for i = 1:N
diam(i) = mean([prop(i).MajorAxisLength prop(i).MinorAxisLength],2);
radio(i) = diam(i)/2;
end 


% Determinar si tiene tumor o no:
density = [prop.Solidity];
area = [prop.Area];
h_dense_area = density>0.5;
max_area = max(area(h_dense_area));
tumor_label= find(area==max_area);
circularidades = [prop.Circularity];
ecc = [prop.Eccentricity];

% Mostrar caracteristicas
w = waitforbuttonpress;
   
if w ==0
 
if  prop(1).Circularity < 0.1 && prop(1).Area > 2000 || prop(2).Circularity<0.3 
    
    obj = L== 1;
    craneo = cb.*uint8(obj);
    craneo1 = insertObjectAnnotation(craneo,"rectangle",prop(1).BoundingBox,"Craneo", ...
    "Color",'cyan',"TextColor","white");

    x = prop(1).BoundingBox(1)+10;
    y = prop(1).BoundingBox(2)+prop(1).BoundingBox(1);
    data = {'Diametro: ' num2str(diam(1),'%0.2f') 'mm',...
            'Perimetro: ' num2str(prop(1).Perimeter,'%0.2f') 'mm'};
    imshow(craneo1)
    hold on
    text('units','pixels','position',[x y],'fontsize',10,'string',data,'Color','y') 
    title("Encefalo detectado sin tumor")
       
else 

  if max_area > 100 
     
    
    text_str = cell(2,1);
    c = "CRANEO: ";
    t = "TUMOR: ";
    nombre = [c t];
    area_ = [prop(1).Area prop(tumor_label).Area]; 
    diametro = [diam(1) diam(tumor_label)];
    rad = [radio(1) radio(tumor_label)];
    perimetro = [prop(1).Perimeter prop(tumor_label).Perimeter];

    line = newline();
    for ii=1:2
        text_str{ii} = ['' char(nombre(ii)) ,line, ...
                        'Diametro: ' num2str(diam(ii),'%0.2f') 'mm ',line,...
                        'Perimetro: ' num2str(prop(ii).Perimeter,'%0.2f') 'mm '];
    end

    % Se definen las posiciones del craneo y el tumor
    x1 = prop(1).BoundingBox(3)-200;
    y1 = prop(1).BoundingBox(3)+80;
    x2 = prop(tumor_label).BoundingBox(1)-30;
    y2 = prop(tumor_label).BoundingBox(2);
    position = [x1 y1; x2 y2]; 
    box_color = {'cyan','yellow'};
    RGB = insertText(cb,position,text_str,'FontSize',8,'BoxColor',...
    box_color,'BoxOpacity',0.4,'TextColor','white');

    % Se muestra la imagen.
       
    figure, imshow(RGB)
    title('Encefalo con tumor');
   end

end 
end
