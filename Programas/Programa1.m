%% Electiva: Procesamiento de imagenes
%  Estudiante: Marlen Sofia Muñoz
%  Deteccion de tumores cerebrales con segmentacion manual.
clear all; clc;

a = imread('imagen1.jpg');
%Converetir a escala de grises 
a=rgb2gray(a);
ar= double(a);
s = size(a);

%Filtro pasa alta para remover ruido
arc = ar*0;
kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1]/8;   % filtro de promedio- eliminando frecuencias altas

for i= 2:s(1)-1
    for j= 2:s(1)-1
        ventana = ar(i-1:i+1, j-1:j+1);
        producto = ventana .* kernel;
        pix = sum(sum(producto));   %f[x,y]*g[x,y]
        arc(i,j) = pix;
    
     end
end
alf = ar-arc;

%filtro Max-min
arc=alf*0;
armediana = alf*0;  %reserva de memoria
arout= alf;
arminmax = alf*0; 

for i= 2:s(1)-1
    for j= 2:s(1)-1
        ventana = alf(i-1:i+1, j-1:j+1);
        producto = ventana .* kernel;
        pix = sum(sum(producto));   %f[x,y]*g[x,y]
        arc(i,j) = pix;

        if alf(i,j) < 10
           arout(i,j) = 0;
        end
        vector= ventana(:);
        vector = sort(vector);
       
        % Max-min  - Pasa Altas
        dif_sup = vector(9) - arout(i,j);
        dif_inf = arout(i,j) - vector(1);
     
        if  dif_sup <= dif_inf
            arminmax(i,j) = vector(9);
        else
            arminmax(i,j) = vector(1);
        end
           
    end
end

%Despliege de Filtros
figure(1), subplot(1,3,1), imshow(uint8(ar)), title('Imagen Original')
figure(1), subplot(1,3,2), imshow(uint8(alf)), title('Filtro pasa alta')
figure(1), subplot(1,3,3), imshow(uint8(arminmax)), title('Filtro Max-min')


%Segmentacion
T=80;
c= arminmax>T;

% Filtros morfológicos.
BW1 = bwareaopen(c,400);
BW2 = bwmorph(BW1,"fill",inf);
BW3 = bwmorph(BW2,"bridge",inf);
BW4 = bwmorph(BW3,"majority",inf);
BW5 = bwmorph(BW4,"close",inf);
BW6 = bwmorph(BW5,"clean");


%Etiquetar elementos
[L, y] = bwlabel(BW6);
cb= a+uint8(BW6);
figure; imshow(cb)

%Calcular propiedades objetos

prop = regionprops(L,'all');
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
for i = 1:y
diam(i) = mean([prop(i).MajorAxisLength prop(i).MinorAxisLength],2);
radio(i) = diam(i)/2;
end 


% Se Determina si tiene tumor o no y muestran las caracteristicas:
density = [prop.Solidity];
area = [prop.Area];
h_dense_area = density>0.5;
max_area = max(area(h_dense_area));
tumor_label= find(area==max_area);
circularidades = [prop.Circularity];
ecc = [prop.Eccentricity];


w = waitforbuttonpress;
   
if w ==0
 
if  y == 1 && prop(1).Circularity < 0.1 && prop(1).Area > 2000 
    
    obj = L== 1;
    craneo = a.*uint8(obj);
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
    diametro = [diam(1) diam(tumor_label)];
    perimetro = [prop(1).Perimeter prop(tumor_label).Perimeter];

    line = newline();
    for ii=1:2
        text_str{ii} = ['' char(nombre(ii)), line, ...
                        'Diametro: ' num2str(diam(ii),'%0.2f') 'mm ',line,...
                        'Perimetro: ' num2str(prop(ii).Perimeter,'%0.2f') 'mm '];
    end

    % se definen las posiciones:
    x1 = prop(1).BoundingBox(3)-200;
    y1 = prop(1).BoundingBox(3)+80;
    x2 = prop(tumor_label).BoundingBox(1)-30;
    y2 = prop(tumor_label).BoundingBox(2);
    position = [x1 y1; x2 y2]; 
    box_color = {'cyan','yellow'};
    

    RGB = insertText(cb,position,text_str','FontSize',10,'BoxColor',...
    box_color,'BoxOpacity',0.4,'TextColor','white');

    % Se muestra la imagen
        figure, imshow(RGB)
    title('Encefalo con tumor');
   
   end
end 
end