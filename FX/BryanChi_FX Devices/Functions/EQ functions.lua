-- @noindex



ProQ3 = {LT_EQBand={};GainDrag = {};Band_UseState={};DspRange={};SpectrumExist={};}
ProQ3.Width = 340
ProQ3.SpecWait=0
FreqValueDrag={}
fftsize = 4096
xscale=300/(fftsize-4) 
wsc=ProQ3.Width/math.log(900)   --- 340 = width of pro q window
SpectrumX = 0
SpectrumY = 0
OUTPUT=0

NodeDrag={}
XposNode = {}
ONE_OVER_SAMPLE_RATE = 1 / (30000 * 2)
Euler = 2.71828182845904523
Hz = 6
A = 2
Q = 0.5

MAX_FREQ = 30000
max_freq = 30000
min_freq = 10;
MIN_FREQ = 10;
FREQ_LOG_MAX = math.log(MAX_FREQ / MIN_FREQ);

MAX_Q = 40;
MIN_Q = 0.15;
freq_log_max = math.log(max_freq / min_freq);
NodeFreq = {}




function determineBandColor(Band) -- for pro q 3
    if      Band == 1 or Band == 9  or Band == 17  then Clr_HalfAlpha = 0x69B45D55 
    elseif  Band == 2 or Band == 10 or Band == 18  then Clr_HalfAlpha = 0x2D91E355
    elseif  Band == 3 or Band == 11 or Band == 19  then Clr_HalfAlpha = 0xC530E555
    elseif  Band == 4 or Band == 12 or Band == 20  then Clr_HalfAlpha = 0xF51B1D55
    elseif  Band == 5 or Band == 13 or Band == 21  then Clr_HalfAlpha = 0x571EF555
    elseif  Band == 6 or Band == 14 or Band == 22  then Clr_HalfAlpha = 0xC1FF1A55
    elseif  Band == 7 or Band == 15 or Band == 23  then Clr_HalfAlpha = 0x30C2FF55
    elseif  Band == 8 or Band == 16 or Band == 24  then Clr_HalfAlpha = 0x00e49655
    end
    if      Band == 1 or Band == 9  or Band == 17  then Clr_FullAlpha = 0x69B45Dff 
    elseif  Band == 2 or Band == 10 or Band == 18  then Clr_FullAlpha = 0x2D91E3ff
    elseif  Band == 3 or Band == 11 or Band == 19  then Clr_FullAlpha = 0xC530E5ff
    elseif  Band == 4 or Band == 12 or Band == 20  then Clr_FullAlpha = 0xF51B1Dff
    elseif  Band == 5 or Band == 13 or Band == 21  then Clr_FullAlpha = 0x571EF5ff
    elseif  Band == 6 or Band == 14 or Band == 22  then Clr_FullAlpha = 0xC1FF1Aff
    elseif  Band == 7 or Band == 15 or Band == 23  then Clr_FullAlpha = 0x30C2FFff
    elseif  Band == 8 or Band == 16 or Band == 24  then Clr_FullAlpha = 0x00e496ff
    end
    if      Band == 1 or Band == 9  or Band == 17  then Clr_Brighter = 0x96CA8Dff 
    elseif  Band == 2 or Band == 10 or Band == 18  then Clr_Brighter = 0x6CB2EBff
    elseif  Band == 3 or Band == 11 or Band == 19  then Clr_Brighter = 0xC530E5ff
    elseif  Band == 4 or Band == 12 or Band == 20  then Clr_Brighter = 0xF51B1Dff
    elseif  Band == 5 or Band == 13 or Band == 21  then Clr_Brighter = 0x865affff
    elseif  Band == 6 or Band == 14 or Band == 22  then Clr_Brighter = 0xccef6eff
    elseif  Band == 7 or Band == 15 or Band == 23  then Clr_Brighter = 0x30C2FFff
    elseif  Band == 8 or Band == 16 or Band == 24  then Clr_Brighter = 0x00e496ff
    end



    return Clr_HalfAlpha, Clr_FullAlpha,Clr_Brighter
    
end

function explode_rgba(rgba)
    return
    ((rgba >> 24) & 0xFF) / 255,
    ((rgba >> 16) & 0xFF) / 255,
    ((rgba >> 8 ) & 0xFF) / 255,
    (rgba         & 0xFF) / 255
end
function _svf_bp(freq, q)

    g = math.tan(math.pi * freq/SAMPLE_RATE);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 0;
    m1 = 1/q;
    m2 = 0;
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);
end

function _svf_bs(freq, q)

    g = math.tan(math.pi * freq/SAMPLE_RATE);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 1;
    m1 = -k;
    m2 = 0;
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);
end

function svf_bs(freq, q)

    nlp = 1;
    onepole = 0;
    _svf_bs(freq, q);
end

function svf_bp(freq, q)
    nlp = 1;
    onepole = 0;
    _svf_bp(freq, q);
end


function per_to_q(x, range)

    Q_LOG_MAX = math.log(MAX_Q / MIN_Q,5);

    return MIN_Q * (Euler ^(Q_LOG_MAX * x / range))
end

function q_to_per(q, range) 
    return range * math.log(q / MIN_Q) / Q_LOG_MAX;
end

function _zdf_eq(freq, q, gain)
    
    A = gain; --10.0 ^ (gain / 20.0);
    g = math.tan(math.pi * freq/SAMPLE_RATE);
    k = 1.0 / (q * A);
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 1;
    m1 = k*(A*A-1);
    m2 = 0;
    rbj_eq(freq, q, gain);
    return zdf_set_coeffs(a1, a2, a3, m0, m1, m2);
end


function zdf_eq(freq, q, gain)
    --instance(nlp, onepole)
    
    nlp = 1;
    onepole = 0;
    this._zdf_eq(freq, q, gain);
end

function rbj_eq(freq, q, gain)
    --instance(a1, a2, b0, b1, b2)

    
    w0 = 2*math.pi * math.min(freq / SAMPLE_RATE, 0.49);
    alpha = math.sin(w0) / (2*q);
    a = gain; --math.sqrt(gain);
    
    b0 = 1 + alpha * a;
    b1 = a1 
    a1 = -2 * math.cos(w0);
    b2 = 1 - alpha * a;
    a0 = 1 + alpha / a;
    a2 = 1 - alpha / a;
    
    return rbj_scale(a0)
end

function db_to_y(db) 
    DB_EQ_RANGE = 60
    m = 1.0 - (((db / DB_EQ_RANGE) / 2) + 0.5);
    return - (m * 200 - 100)
    --return TOP_MARGIN+(m * (gfx_h - (gfx_texth*2) - BOTTOM_MARGIN - (RAISED_BOTTOM * ENABLE_RAISED_BOTTOM)));
end


function freq_to_x(freq) 
    ProQ3.Width = 340 
return 0 + (340 * math.log(freq / 10) / 30000 );
end

function spectrum1_to_y(zo) 
    gfx_h = 190
    return 0 + (1.0 - zo) * gfx_h ;
end

function _svf_ls(freq, q, gain)

    A = gain; --10 ^ (gain / 40.0);
    g = math.tan(math.pi * freq/SAMPLE_RATE) / math.sqrt(A);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 1;
    m1 = k*(A - 1);
    m2 = (A * A - 1);
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);
end

function svf_ls(freq, q, gain)


    nlp = 1;
    onepole = 0;
    _svf_ls(freq, q, gain);
end

function _svf_hs(freq, q, gain)
    A = gain; --10 ^ (gain / 40.0);
    g = math.tan(math.pi * freq/SAMPLE_RATE) * math.sqrt(A);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = A * A;
    m1 = k * (1 - A) * A;
    m2 = (1 - A * A);
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);
end

function svf_st(freq, q, gain)

    nlp = 3;
    onepole = 0;
    gain2 = 10^((-gain) / 40);
    gainn = 10^(gain / 40);
    
    _svf_hs(freq, q, gainn);

    --_svf_ls(freq, q, gain2)
    A = gain2 ; --10 ^ (gain / 40.0);
    g = math.tan(math.pi * freq/SAMPLE_RATE) / math.sqrt(A);
    k = 1.0 / q;
    a1 =   1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = a3+ g * a2;
    m0 = m0 ;
    m1 = m1+ k*(A - 1)  ;
    m2 = m2+ (A * A - 1);


end

function svf_hs(freq, q, gain)

    nlp = 1;
    onepole = 0;
    _svf_hs(freq, q, gain);
end

    
function rbj_ls(freq, q, gain)

    w0 = 2*math.pi * math.min(freq / SAMPLE_RATE, 0.49);
    cos_w0 = math.cos(w0);
    a = gain; --sqrt(gain);

    tmp0 = 2 * math.sqrt(a) * math.sin(w0) / (2 * q);
    tmp1 = (a + 1) - (a - 1) * cos_w0;
    tmp2 = (a + 1) + (a - 1) * cos_w0;

    b0 = a * (tmp1 + tmp0);
    b1 = 2 * a * ((a - 1) - (a + 1) * cos_w0);
    b2 = a * (tmp1 - tmp0);
    a0 = tmp2 + tmp0;
    a1 = -2 * ((a - 1) + (a + 1) * cos_w0);
    a2 = tmp2 - tmp0;
    

    return rbj_scale(a0);
end

function rbj_hs(freq, q, gain)

    w0 = 2*math.pi * math.min(freq / SAMPLE_RATE, 0.49);
    cos_w0 = math.cos(w0);
    a = gain; --sqrt(gain);

    tmp0 = 2 * math.sqrt(a) * math.sin(w0) / (2 * q);
    tmp1 = (a + 1) - (a - 1) * cos_w0;
    tmp2 = (a + 1) + (a - 1) * cos_w0;

    b0 = a * (tmp2 + tmp0);
    b1 = -2 * a * ((a - 1) + (a + 1) * cos_w0);
    b2 = a * (tmp2 - tmp0);
    a0 = tmp1 + tmp0;
    a1 = 2 * ((a - 1) - (a + 1) * cos_w0);
    a2 = tmp1 - tmp0;

    return rbj_scale(a0);
end

function rbj_hp(freq, q)

    w0 = 2*math.pi * math.min(freq / SAMPLE_RATE, 0.49);
    cos_w0 = math.cos(w0);
    alpha = math.sin(w0) / (2*q);

    b1 = -1 - math.cos_w0;
    b0 = b2 
    b2 = -0.5 * b1;
    a0 = 1 + alpha;
    a1 = -2 * math.cos_w0;
    a2 = 1 - alpha;

    return rbj_scale(a0);
end


function rbj_scale(a0)

    
    local scale = 1/a0;

    a1 = a1 *  scale;
    a2 = a2 * scale;

    b0 = b0 * scale;
    b1 = b1 * scale;
    b2 = b2 *  scale;

    return a0
end
SAMPLE_RATE = 60000

function freq_to_scx(freq) 

    MAX_FREQ = 30000
    MIN_FREQ = 10;
    FREQ_LOG_MAX = math.log(MAX_FREQ / MIN_FREQ);
    Witdth = 340
    return ProQ3.Width * math.log(freq / MIN_FREQ) / FREQ_LOG_MAX;
end

function rbj_hp(freq, q)

    w0 = 2* math.pi * math.min(freq / 60000, 0.49); --60000 is supposed to be sample rate
    cos_w0 = math.cos(w0);
    alpha = math.sin(w0) / (2*q);

    b1 = -1 - cos_w0;
    b0 = -0.5 * b1;
    b2 = -0.5 * b1;
    a0 = 1 + alpha;
    a1 = -2 * cos_w0;
    a2 = 1 - alpha;


    return rbj_scale(a0)
end

function rbj_lp(freq, q)

    w0 = 2* math.pi * math.min(freq / 60000, 0.49);
    cos_w0 = math.cos(w0);
    alpha = math.sin(w0) / (2*q);

    b1 = 1 - cos_w0;
    b0 = 0.5 * b1;
    b2 = 0.5 * b1;
    a0 = 1 + alpha;
    a1 = -2 * cos_w0;
    a2 = 1 - alpha;

    return rbj_scale(a0);
end   

function svf_onepole(mode, cutoff)
    passtype = mode;
    if passtype == 0  then 
    -- Low pass
    W = math.tan(math.pi * cutoff / SAMPLE_RATE);
    N = 1/(1+W);
    B0 = W * N;
    B1 = B0;
    A1 = N * (W-1);  
    return A1
    else
    -- High pass

    W = math.tan(math.pi * cutoff / SAMPLE_RATE);
    N = 1/(1+W);
    B0 = N;
    B1 = -B0;
    A1 = N * (W-1);
    return A1
    end
end

function svf_single_hp(freq, q)

    g = math.tan(math.pi * freq/SAMPLE_RATE);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 1.0;
    m1 = -k;
    m2 = -1.0;
    --rbj_hp(freq, q);
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);

    --svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);

    cutoff = freq;

    op0 = svf_onepole(1, cutoff);
    op1 = svf_onepole(1, cutoff);
    return op0,op1
end

function zdf_single_lp(freq, q)


    g = math.tan(math.pi * freq/SAMPLE_RATE);
    k = 1.0 / q;
    a1 = 1.0 / (1.0 + g * (g + k));
    a2 = g * a1;
    a3 = g * a2;
    m0 = 0;
    m1 = 0;
    m2 = 1;
    --rbj_lp(freq, q);
    svf_set_coeffs(g, k, a1, a2, a3, m0, m1, m2);

    --a1,a2,a3,m0,m1,m2 = zdf_set_coeffs(a1, a2, a3, m0, m1, m2);
    cutoff = freq;

    op0 = svf_onepole(0, cutoff)
    op1 = svf_onepole(0, cutoff)
    return op0, op1
end

function magnitude_to_01(m, freq)


    ceiling = 0;
    noise_floor = -90;

    db = 10 * math.log10(m);

    -- Tilt around 1kHz
    if        tilt ~= 0.0 then db = db+ tilt * ((math.log(freq) / math.log(2)) - (math.log(1024) / math.log(2))) end

    return 1.0 - ((db - ceiling) / (noise_floor - ceiling));
end
function db_to_gain(db) 
    return 10^(db / 21); -- 21 is 40 in original script
end
function db_to_gain30(db) 
    return 10^(db / 21); -- 21 is 40 in original script
end



function zdf_lp(freq, q, slope)
    --instance(nlp, cas1, cas2, cas3, cas4, cas5, cas6, cas7, cas8, cas9, onepole)

    nlp = slope;
    if slope == 0 then onepole = 1 else onepole = 0 end

    cas0 =  zdf_single_lp(freq, q);
    cas1 = zdf_single_lp(freq, q);
    cas2 = zdf_single_lp(freq, q);
    cas3 = zdf_single_lp(freq, q);
    cas4 = zdf_single_lp(freq, q);
    cas5 = zdf_single_lp(freq, q);
    cas6 = zdf_single_lp(freq, q);
    cas7 = zdf_single_lp(freq, q);
    cas8 = zdf_single_lp(freq, q);
    cas9 = zdf_single_lp(freq, q);

    return cas0,cas1,cas2,cas3,cas4,cas5,cas6,cas7,cas8,cas9
end



function svf_hp(freq, q, slope)

    nlp = slope;
    if slope == 0 then onepole = 1 else onepole = 0 end

    cas0 = svf_single_hp(freq, q);
    cas1 = svf_single_hp(freq, q);
    cas2 = svf_single_hp(freq, q);
    cas3 = svf_single_hp(freq, q);
    cas4 = svf_single_hp(freq, q);
    cas5 = svf_single_hp(freq, q);
    cas6 = svf_single_hp(freq, q);
    cas7 = svf_single_hp(freq, q);
    cas8 = svf_single_hp(freq, q);
    cas9 = svf_single_hp(freq, q);

    return cas0,cas1,cas2,cas3,cas4,cas5,cas6,cas7,cas8,cas9

end





function svf_set_coeffs(tg, tk, ta1, ta2, ta3, tm0, tm1, tm2)
    --instance(g, k, a1, a2, a3, m0, m1, m2, t_g, t_k, t_a1, t_a2, t_a3, t_m0, t_m1, t_m2, s_g, s_k, s_a1, s_a2, s_a3, s_m0, s_m1, s_m2, iter_t)

    iter_t = 0.0;

    -- Start coefficients
    s_g = g;
    s_k = k;
    s_a1 = a1;
    s_a2 = a2;
    s_a3 = a3;
    s_m0 = m0;
    s_m1 = m1;
    s_m2 = m2;

    -- Target coefficients
    t_g = tg;
    t_k = tk;
    t_a1 = ta1;
    t_a2 = ta2;
    t_a3 = ta3;
    t_m0 = tm0;
    t_m1 = tm1;
    t_m2 = tm2;
end



function magnitude(freq)
-- instance(g, k, m0, m1, m2, a1, a2, a3)
    --local(zr, zi, zrr, gsq, gm1, gk, twogsq, a, zsq_i, zsq_r, twoz_r, twoz_i, nr, ni, dr, di, norm, ddi, ddr, x, y, s)

    -- exp(complex(0.0, -2.0 * pi) * frequency / sampleRate)
    zr = 0.0;
    zi = -2.0 * math.pi;
    
    zr = zr * freq * ONE_OVER_SAMPLE_RATE;
    zi = zi * freq * ONE_OVER_SAMPLE_RATE;
    zr = math.exp(zr);
    
    zrr = zr;
    zr = zrr * math.cos(zi);
    zi = zrr * math.sin(zi);

    gsq    = g * g;
    gm1    = g * m1;
    gk     = g * k;
    twogsq = gsq * 2.0;

    -- z * z
    a = zr * zr - zi * zi;
    zsq_i = zi * zr + zr * zi;
    zsq_r = a;

    -- z * 2.0
    twoz_r = zr * 2;
    twoz_i = zi * 2;
    
    -- Numerator complex
    nr = gsq * m2 * (zsq_r + twoz_r + 1.0) - gm1 * (zsq_r - 1.0);
    ni = gsq * m2 * (zsq_i + twoz_i) - gm1 * (zsq_i);
    
    -- Denominator complex
    dr = gsq + gk + zsq_r * (gsq - gk + 1.0) + zr * (twogsq - 2.0) + 1.0;
    di = zsq_i * (gsq - gk + 1.0) + zi * (twogsq - 2.0);

    -- Numerator / Denominator
    norm = dr * dr + di * di;
    a = (nr * dr + ni * di) / norm;
    ddi = (ni * dr - nr * di) / norm;
    ddr = a;

    -- abs(m0_ + (Numerator / Denominator)
    x = m0 + ddr;
    y = ddi;
    s = math.max(math.abs(x), math.abs(y));
    x = x/ s;
    y = y/ s;

    -- Return magnitude
    return  s * math.sqrt(x * x + y * y);
end


function zdf_magnitude(freq)
    --instance(rbj, nlp, onepole, cas1, cas2, cas3, cas4, cas5, cas6, cas7, cas8, cas9, cutoff, op0, op1)
    --local(m)

    -- Our svf magnitude maps to the same magnitude z transfer function as biquad

    m = 1.0;

    -- Apply two pole (12dB steps)
    if  nlp > 0  then  m =  m *  magnitude(freq)         end    --12
    if  nlp > 2  then  m =  m *  magnitude(freq)         end 
    if  nlp > 4  then  m =  m *  magnitude(freq)         end 
    if  nlp > 6  then  m =  m *  magnitude(freq)         end 
    if  nlp > 8  then  m =  m *  magnitude(freq)         end 
    if  nlp > 10 then  m =  m *  magnitude(freq )        end 
    if  nlp > 12 then  m =  m *  magnitude(freq )        end 
    if  nlp > 14 then  m =  m *  magnitude(freq )        end 
    if  nlp > 16 then  m =  m *  magnitude(freq )        end 
    if  nlp > 18 then  m =  m *  magnitude(freq )        end    --120 

    -- Apply one pole (6dB)

    if onepole == 1 then

    wdcutoff = math.pi * (cutoff / SAMPLE_RATE);
    coff = math.tan(wdcutoff);

    wdeval = math.pi * (freq / SAMPLE_RATE);
    svalue = math.tan(wdeval);

    if passtype == 0 then 
        -- lp
        m = m* 1.0 / math.sqrt(1 + ((svalue/coff)^2));
    else
        -- hp
        m = m* 1.0 / math.sqrt(1 + ((coff/svalue)^2));      
    end
    end

    return m 
end

function x_to_freq(x) 
    max_freq = 30000
    min_freq = 10
    x = min_freq * (Euler ^(freq_log_max * (x) / (340))); -- 340 is width
    return math.max(math.min(x, max_freq), min_freq);

end

function freq_to_x_MyOwn(y)
    Euler = 2.71828182845904523
    return (340 * math.log(y/10, Euler)) / 8.00636757
end


for i=1, 340 , 1 do -- 340 is width
    iToFreq = x_to_freq(i)  
    if iToFreq >50 and iToFreq <51 then  iPos50 = i end
    if iToFreq >99 and iToFreq <102 then  iPos100 = i end
    if iToFreq >198 and iToFreq <201 then  iPos200 = i end
    if iToFreq >490 and iToFreq <500 then  iPos500 = i end
    if iToFreq >990 and iToFreq <1020 then  iPos1k = i end
    if iToFreq >1980 and iToFreq <2010 then iPos2k = i end
    if iToFreq >4900 and iToFreq <5050 then iPos5k = i end
    if iToFreq >9990 and iToFreq <10300 then iPos10k = i end
end




function Calc_4ptBezier (x1, y1 , x2, y2, x3,y3,x4,y4,t)
    
    X = (1 - t)^3*x1 + 3*(1 - t)^2*t*x2 + 3* (1 - t) *t^2*x3 + t^3*x4  
    Y = ( 1 - t)^3*y1 + 3*(1 - t)^2*t*y2 +3*(1 - t)*t^2*y3 + t^3*y4

    return X, Y
end






function syncProQ_DispRange(Actual_dB_Val)
                if  Actual_dB_Val == 30 then Output = 1 
                elseif Actual_dB_Val == 12  then Output =2.5
                elseif Actual_dB_Val == 6   then Output =5
                elseif Actual_dB_Val == 3   then Output =10
                end
                return Output
            end
