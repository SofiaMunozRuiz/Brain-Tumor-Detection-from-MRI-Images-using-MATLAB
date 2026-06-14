%% Electiva: Procesamiento de imagenes
%  Estudiante: Marlen Sofia Muñoz
%  Deteccion de tumores cerebrales usando segmentacion con k-mean.

clear all; clc;
a = imread('imagen18.jpg');

%Converetir a escala de grises 
a=rgb2gray(a);
ar= double(a);
s = size(a);

%Aplicar filtro pasa alta para remover ruido
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

        if alf(i,j) < 5
            arout(i,j) = 0;
        end
        vector= ventana(:);
        vector = sort(vector);
       
        % Max-min  - Pasa Altas
        dif_sup = vector(9) - arout(i,j);
        dif_inf = arout(i,j) - vector(1);
     
        if dif_sup <= dif_inf
            arminmax(i,j) = vector(9);
        else
            arminmax(i,j) = vector(1);
        end
           
    end
end


% Despliege
figure(1), subplot(1,3,1), imshow(uint8(ar)), title('Imagen Original')
figure(1), subplot(1,3,2), imshow(uint8(alf)), title('Filtro pasa alta')
figure(1), subplot(1,3,3), imshow(uint8(arminmax)), title('Filtro Max-min')


% Segmentación K-means
imData = reshape(arminmax,[],1);
nn=[2.3728;137.8732;65.2422];
[IDX, nn] = kmeans(imData,3,'Start',nn);
imIDX = reshape(IDX, size(a));

figure(2), imshow(imIDX,[]),title('Image');

% Region por separado
bw = (imIDX==2);
se = ones(2);
bw = imopen(bw,se);
bw = bwareaopen(bw,300);
figure(3), imshow(bw);

% Filtro morfologicos
BW2 = bwmorph(bw,"fill",inf);
BW3 = bwmorph(BW2,"bridge",inf);

% Etiquetado elementos
[L, N] = bwlabel(BW3);
cb= a+uint8(BW3);
figure(4); imshow(cb)

% Obtencion de propiedades de los cerebros
prop = regionprops(L,'all');
hold on 

% Obtencion de rectangulos
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


% Determinar si tiene tumor o no y mostrar caracteristicas:
density = [prop.Solidity];
area = [prop.Area];
h_dense_area = density > 0.5;
max_area = max(area(h_dense_area));
tumor_label= find(area==max_area);
circularidades = [prop.Circularity];
ecc = [prop.Eccentricity];

w = waitforbuttonpress;
   
if w ==0
 
if  N==1
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
    diametro = [diam(1) diam(tumor_label)];
    perimetro = [prop(1).Perimeter prop(tumor_label).Perimeter];
    line = newline();

    for ii=1:2
        text_str{ii} = ['' char(nombre(ii)) ,line, ...
                        'Diametro: ' num2str(diam(ii),'%0.2f') 'mm ',line,...
                        'Perimetro: ' num2str(prop(ii).Perimeter,'%0.2f') 'mm '];
    end
    %Define the positions and colors of the text boxes.
    x1 = prop(1).BoundingBox(3)-200;
    y1 = prop(1).BoundingBox(3)+80;
    x2 = prop(tumor_label).BoundingBox(1)-30;
    y2 = prop(tumor_label).BoundingBox(2);
    position = [x1 y1; x2 y2]; 
    box_color = {'cyan','yellow'};
    %Insert the text with new font size, box color, opacity, and text color.

    RGB = insertText(cb,position,text_str,'FontSize',8,'BoxColor',...
    box_color,'BoxOpacity',0.4,'TextColor','white');

    %Display the image.
    
    
    figure, imshow(RGB)
    title('Encefalo con tumor');
   
    disp('tumor');
  end

end 
end


