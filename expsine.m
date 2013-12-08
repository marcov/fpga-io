x = linspace(0, 2*pi, 256);

y = exp(sin(x));

offset  = min (y);
coeff = 255 / (max(y) - min (y));

w = round((-y + offset) * coeff + 255) 
min(w)
max(w)
