#import "src/template.typ": *
#import "@preview/diagraph:0.2.1": *

// Take a look at the file `template.typ` in the file panel
// to customize this template and discover how it works.
#show: project.with(
  title: "Visual Computing",
  authors: (
    (name: "Silvan Metzker", email: "smetzker@ethz.ch"),
    (name: "Jacques Hoffmann", email: "jacques.hoffmann@math.ethz.ch"),
  ),
  date: "January 25, 2024",
)

= Computer Vision
== Digital images & sensors
#colorbox(title: [Charge coupled device (CCD)])[
  An array of photosites (a bucket of electrical charge) hold charge proportional to incident light intensity during exposure. Charges move down through sensor array, ADC (analog-digital-converter) measures line-by-line.
    #grid(columns: (70pt, 80pt, 80pt), gutter: 5pt,
    [*Blooming*: Oversaturated photosites cause vertical channels to "flood"],
    [*Bleed-/Smearing*: Bright light hits photosites while charge is in transit, worse with shorter exp. time],
    [*Dark current*: CCDs produce thermally generated charge: random noise despite darkness. ], 
    block(image("src/bloom.png", width: 100%), clip: true, radius: 3pt),
    block(image("src/smear.png", width: 100%), clip: true, radius: 3pt),
    block(image("src/dark-curr.png", width: 100%), clip: true, radius: 3pt),
    )
]

#colorbox(title: [CMOS sensors])[
  Mostly same as CCD, but each sensor has amplifier. Cheaper, lower power, no blooming, on-chip integration with other components, but less sensitive and more noise. Rolling shutter is an issue for sequential read-out of lines.
]

#colorbox(title: [Nyquist-Shannon sampling theorem], color: black, inline: false)[
  Sample frequency must be at least twice as big as the highest frequency in the signal/image to avoid aliasing. \
]

*Quantization*: real-valued function get digital values. 

*Geometric resolution*: \#pixels per area \
*Radiometric resolution*: \#bits per pixel
#grid(columns: (auto, 94pt), gutter: 5pt,
    [*Additive Gaussian Noise*],
    [*Poisson (shot) N.*],
    [$I(x, y) = f(x, y) + c$ \
    where $c tilde N(0, sigma^2)$ \ s.t.: $"pdf"(c) = (2 pi sigma^2)^(-1) e^(-c^2 / 2 sigma^2)$],
    [$"pdf"(k) = (lambda^k e^(-lambda)) / (k!)$],
    [*Rician noise (MRI)*],
    [*Multiplicative N.*],
    [$"pdf"(I) = 1 / (sigma^2) exp((-(I^2 + f^2)) / (2 sigma^2)) I_0 ((I f) / (sigma^2))$],
    [$I = f + f c$],
    [*Signal to noise ratio (SNR)*],
    [*PSNR (P: Peak)*],
    [$s = F / sigma$ where \ $F = 1 / (X Y) sum_{x = 1}^X sum_{y = 1}^Y f(x, y)$],
    [$s_("peak") = (F_("max")) / sigma$],
)

*Color camera concepts*: Prism (splitting light, 3 sensors, requires good alignment), Filter mosaic (coat filter on sensor, grid, introduces aliasing), Filter wheel (rotate filter in front of lens, static image), CMOS sensor (absorbing colors at different depths)

#grid(columns: (auto, auto), gutter: 1em,
image("src/bilinear-interpolation.png", height: 8.5em),
[*Bilinear Interpolation*: Reconst. from 2D sampling, ass. linear behav.: $ f(x,y)=(1-a)(1-b) dot f(i,j) \ + a(1-b) dot f(i+1,j) \ + a b dot f(i+1, j+1)\ +(1-a)b dot f(i,j+1) $]

)
== Image segmentation
Partition image into regions of interest.

*Complete segmentation* of $I$: regions $R_1, ..., R_N$ s.t. $I = union.big_(i = 1)^N R_i$ and $R_i sect R_j = emptyset "for" i != j$.

#colorbox(title: [Thresholding], color: black)[
  produces binary image by labeling pixels _in_ or _out_ by comparing to some threshold $T$.
]
$B(x, y) = 1 "if" I(x, y) >= T "else" 0$, finding $T$ with trial and error, compare results with ground truth.

*Chromakeying* choose special background color $bold(x)$, then segmentation using: $I_alpha = norm(bold(I) - bold(x)) > T$. Issues: hard $alpha$-mask, variation not same in 3 channels.

#colorbox(title: [Receiver operating characteristic (ROC)], inline: false)[
  ROC curve describes performance of binary classifier. Plots (y, sensitivity, $"TPR"="TP" / ("TP" + "FN")$) against (x, 1-specificity, $"FP" / ("FP" + "TN")$). We can choose operating point with gradient $beta = N / P dot.c (V_"TN" + C_"FP") / (V_"TP" + C_"FN")$ where $V$ value and $C$ cost.
]

*Pixel neighbourhoods* or 4/8-connectivity: 4-neighb. means horiz. + vert. or 8-neighb. with diag.

#colorbox(title: [Region growing], color: black)[
  Start from seed point / region, include pixels if some criteria is satisfied (e.g. pixel-pixel threshold or with std-deviation $sigma$, mean $mu$ of graylevels in region: $(I(x, y) - mu)^2 < (n sigma)^2$), iterate until no pixels added.
]
Seed region(s) by hand or conservative thresholding

#colorbox(title: [Snakes], color: black)[
  Active contour, polygon, where each point on contour moves away from seed while inclusion criteria in neighborhood is met, often smoothness constraint. Iteratively minimize energy: $E = E_"tension" + E_"stiffness" + E_"image"$
]

#colorbox(title: [Mahalanobis Distance $I_alpha$], inline: false)[
  With $N$ background samples $c_"ref"^i$ and pixel $bold(I)(x,y)$: \
  $bold(I)_alpha = script(sqrt((bold(I)(x,y) - mu)^top Sigma^(-1) (bold(I)(x,y) - mu)))$ with $n>=3$ we get:
  $ inline(Sigma = 1 / (N - 1) sum_(i = 1)^N (c_"ref"^i - mu) (c_"ref"^i - mu)^T "with" mu=1/N sum x_i) $
  We then include pixel $bold(I)(x,y)$ if $bold(I)_alpha < T$.
]

*Markov random fields*: Cost to assign label to each pixel ($psi_1$), cost to assign pair of labels to connected pixels ($psi_2$). Solve with graph cuts, source = FG, sink = BG. Minimize energy in polynomial time using MinCut. To get decent results, we need *alpha estimation* / border matting along edges. With data $d$ we get energy:
$ inline(E(y; theta, "d") = sum_i psi_1(y_i; theta, "d") + sum_(i, j in "edges") psi_2(y_i, y_j; theta, "d")) $

== Image filtering
*Shift-invariant*: same for all pixels, e.g. indep. on $x,y$\
*Linear*: $L(alpha I_1 + beta I_2)=alpha L(I_1)+beta L( I_2)$\
*Separable*: kernel $K(m, n) = f(m) g(n)$ \
*Local*: Does it only depend on local pixels, e.g. not all. \
*Filtering near edges*: clip to black, wrap around, copy edge, reflect across edge, vary filter! \
Corr./conv the same if: $K(x, y)=K(-x,-y)$ \

#colorbox(title: "Correlation", breakable: false)[ 
  Template matching: $I' = K circle.small I$
  
  $I(x, y) = sum_((i, j) in N(x, y)) K(i, j) I(x + i, y + j)$
]

#colorbox(title: "Convolution")[
  Point spread function: $I' = K convolve I$
  $ inline(I'(x, y) = sum_((i, j) in N(x, y)) K(i, j) I(x - i, y - j)) $

  Linear, associative, shift-invariant, commutative (if dimensions are identical). For the continuous case: \
  $ inline(g(x) = f(x) * k(x) = integral_RR f(a) k(x - a) dif a) $
]



#colorbox(title: "Important kernel examples", color: teal, inline: false)[
  #grid(columns: (auto, auto, auto, auto), gutter: 1em,
    [Low-pass \ Mean], $1 / 9 mat(1,1,1; 1,1,1; 1,1,1)$,
    [High-pass], $mat(-1,-1,-1;-1,8,-1;-1,-1,-1)$,
    [Laplacian], $mat(0,1,0; 1,-4,1;0,1,0)$,
    [Prewitt (x)], $mat(-1,0,1;-1,0,1;-1,0,1)$,
    [Gaussian $G_sigma$], [$ 1 / (2 pi sigma^2) e^(-(x^2 + y^2) / (2 sigma^2)) $],
    [Sobel (x)], $mat(-1,0,1; -2,0,2; -1,0,1)$,
    [Diff. (x)], $mat(-1, 1)$, [Central diff.],[(x) $mat(-1, 0, 1)$]
  )
]
The Gaussian kernel is rot. symetric, single lobe, FT is again a Gaussian, separable, easily made efficient.

Note: High-pass usually sums up to 0, low-pass to 1.

$ (partial f) / (partial x) = lim_(epsilon -> 0) (f(x + epsilon, y) -f(x, y)) / epsilon approx (f(x_(n + 1), y) - f(x_n, y)) / (Delta x) $
Hence, diff. leads to the convolution $mat(-1, 1)$

// necessary?
Image sharpening: enhances edges by increasing high frequency components: $I' = I + alpha abs(k convolve I)$ where $k$ high-pass filter, $alpha in [0, 1]$.

// integral images?

== Edge detection
*Laplacian Operator:* Find 0s in 2nd deriv $I''$ to locate edges. Rot. invariant, yields very noisy but thin and uninterrupted edges. 
$nabla^2 f(x, y) = (partial^2 f(x, y)) / (partial x^2) + (partial^2 f(x, y)) / (partial y^2)$

Laplacian is sensitive to noise, thus _apply blur first_: \ *Laplacian of Gaussian* (or suppress edges w/ low gradient magnitude)
$ inline("LoG"(x,y)=- 1/ (pi sigma^4) (1 - (x^2 + y^2) / (2 sigma^2)) exp(-(x^2 + y^2) / (2 sigma^2))) $

#colorbox(title: [Canny edge detector], color: black)[
  Thin, uninterrupted edges, extended more completely than with simple thresh.
  + Smooth image with *Gaussian filter*
  + *Compute grad., mag. & angle* (Sobel, Prewitt, ...)
    $ inline(M(x, y) = sqrt(((partial f) / (partial x))^2 + ((partial f) / (partial y))^2)\, alpha(x, y) = tan^(-1)((partial f) / (partial y) slash.big (partial f) / (partial x))) $
  + *Nonmaxima suppression:* quantize edges normal to 4 dirs, if smaller than either neighb. suppress
  + *Double thresholding:* $T_"high", T_"low"$, keep if $>= T_"high"$ or $>= T_"low"$ and 8-conn. through $>= T_"low"$ to $T_"high"$ px.
  + *Hysteresis:* Reject weak edge pixels not connected with strong edge pixels
]

#colorbox(title: [Hough transformation], color: black)[
  Fits a curve (line, circles, ...) to set of edge pixels (e.g. $y = m x + c$)
  + Subdivide $(m, c)$ plane into discrete bins init to 0
  + Draw line in $(m, c)$ plane for each edge pixel $(x, y)$, incremebnt bins by 1 along line
  + Detect peaks in $(m, c)$ plane.
]
Infinite slopes arise, reparameterize line with $(theta, x)$: $x cos theta + y sin theta = rho$. For circles with known radius: $(x - a)^2 + (y - b)^2 = r^2$, else 3D Hough. _(Loop through all discrete values of 2 params $(x, y)$ corresponding to bins, compute $r$ for $(x, y)$ update 3D bin $(x, y, r)$ like in 2D case, find maximum in 3D bins)_

*Corner detection*: Edges only well localized in single direction. We need acc. local., invar. against shift, rot., scale, brightness, noise robust, repeatability. We define Local displacement sensitivity: $S(Delta x, Delta y) =$ $sum_((x, y) in "window") (f(x, y) - f(x + Delta x, y + Delta y))^2$. Using the Taylor approx. below and $bold(M)$, we get: $f_x = I_x, ...$

$ f(x + Delta x, y + Delta y) approx f(x, y) + f_x (x, y) Delta x + f_y (x, y) Delta y \
bold(M) = sum_((x, y) in "window") mat(f_x^2 (x, y), f_x (x, y) f_y (x, y); f_x (x, y) f_y (x, y), f_y^2(x, y)) $

$ S(Delta x, Delta y) approx mat(Delta x, Delta y) bold(M) mat(Delta x, Delta y)^T approx bold(Delta)^T bold(M) bold(Delta) $

#colorbox(title: [Harris corner detection])[
  Compute matrix $bold(M)$. Compute $C(x, y) = det(bold(M)) - k dot.c ("trace"(bold(M)))^2$ $= lambda_1 lambda_2 - k dot.c (lambda_1 + lambda_2)^2$. Mark as corner if $C(x, y) > T$. Do non max-suppression and for better local., weight central pixels with weights  for sum in $bold(M)$: $G(x - x_0, y - y_0, sigma)$. Compute subpixel local. by fitting parabola to cornerness function.  Invariant to shift, rot, brightness offset, not scaling.
]

#colorbox(title: [Feature Extraction],)[
  *Template Matching*: Check all locations, rotations, and scales. Can be done in time or frequency domain.\
  *SIFT (Scale Invariant Feature Transform)*:
    - Track feature points over images.
    - Use Difference of Gaussian (DoG) to detect blobs.
    - Compute gradient direction histograms.
    - Align images, compare histograms for matches.
    - $"DoG"(x, y) = 1 / k e^((x^2 + y^2) / (k sigma)^2) - e^(-(x^2 + y^2) / (sigma^2)), k = sqrt(2)$
]

== Fourier transform
#colorbox(title: [Fourier transform])[
  represents signal in new basis (in amplitudes & phases of constituent sinusoids).
  
  $ inline(F(f(x))(u) = integral_RR f(x) dot.c exp(-i 2 pi u x) dif x \ F(f(x, y))(u, v) = integral.double_(RR^2) f(x, y) e^(-i 2 pi (u x + v y)) dif x dif y) $
]
Inverse FT exists. Discrete FT: $F = bold(U) f$ where $F$ transformed image, $bold(U)$ FT base, $f$ vectorized image. 
$ inline(F(u, v) = 1 / N sum_(x = 0)^(N - 1) sum_(y = 0)^(N - 1) f(x, y) dot.c e^(-i 2 pi (u x + v y) / N)) $

Relevant: $cos(x) = (e^(i x) + e^(-i x)) / 2 space.quad sin(x) = (e^(i x) - e^(-i x)) / 2$ \
Dirac delta: $delta(x) = 0 "if" x != 0 "else undefined"$ with $integral_(-oo)^infinity delta(x) dif x = 1$ Sampling: Mult with seq. of $delta$-fnts

$F(delta(x - x_0))(u) = e^(-i 2 pi u x_0)$.


#grid(columns: (auto, auto, auto), column-gutter: 1.5em, row-gutter: 0.8em,
  [*Property*], $bold(f(x))$, $bold(F(u))$,
  [Linearity], $alpha f_1(x) + beta f_2(x)$, $alpha F_1(u) + beta F_2(u)$,
  [Duality], $F(x)$, $f(-u)$,
  [Convolut.], $(f * g)(x)$, $F(u) dot.c G(u)$,
  [Product], $f(x) g(x)$, $(F * G)(u)$,
  [Timeshift], $f(x - x_0)$, $e^(-2 pi i u x_0) dot.c F(u)$,
  [Freq. shift], $e^(2 pi i u_0 x) f(x)$, $F(u - u_0)$,
  [Different.], $(dif n) / (dif x^n) f(x)$, $(i / (2 pi) u)^n F(u)$,
  [Multiplic.], $x f(x)$, $i / (2 pi) dif / (dif u) F(u)$,
  [Scaling], $f(a x)$, $1 /(|a|) dot.c F(u / a)$,
)

#image("src/fourier-transforms.png", height: 25em)

$*)$ Holds if $"sinc"(x)=sin(pi x)/(pi x)$ (normalized), \ if $"sinc"(x) = sin(x)/x$ (unnormalized) then:\
$ sinc(pi t) -> "Box"(u) "and" sinc(pi t) -> "Box"(u) $

#colorbox(title: [Image restoration])[
Image degradation is applying kernel $h$ to some image $f$. The inverse $tilde(h)$ should compensate: $f(x) -> h(x) -> g(x) -> tilde(h)(x) -> f$. Determine with $tilde(h) = F^(-1)(1 / F(h))$. Cancellation of freq., noise amplif. Regularize using $tilde(F)(tilde(h))(u, v) = F(h) slash.big (|F(h)|^2 + epsilon)$         
]

== Unitary transforms (PCA / KL)
Images are vectorized row-by-row. Linear image processing algorithms can be written as $g = F f$. Auto-correl. fun.: $R_"ff" = E[f_i dot.c f_i^H] = (F dot.c F^H) / n$.

*Eigenmatrix*: $Phi$ of autocorrelation matrix $R_"ff"$: $Phi$ is unitary, columns form set of eigenvectors of $R_"ff"$: $R_"ff" Phi = Phi Lambda$ where $Lambda$ is a diag. matrix of eigenvecs. $R_"ff"$ is symmetric nonneg. definite, hence $lambda_i >= 0$, and normal: $R_"ff"^H R_"ff" = R_"ff" R_"ff"^H$.

#colorbox(title: "Karhunen-Loeve / Principal component anal. ", inline: false)[
  + Normalize (only if asked): $x'_i = x_i / norm(x_i)$
  + Center data by subtr. mean: $x''_i = x'_i - mu, mu = 1 / N sum x'_i$
  + Compute covar. mat.: $Sigma = 1 / (N - 1) sum x''_i dot (x''_i)^T$
  + Compute eigendecomp. of $Sigma$ by solving $Sigma e = lambda e$ with e.g. SVD ($Sigma = U Lambda U^T$)
  + Define $U_k$ as first k eigenval. of $Sigma$, $U_k = mat(u_1, ..., u_k)$ dirs with largest variance.
  + To store: $v_i="PCA"(x_i) = U_k^T (x_i - mu) = U_k^T dot.c x''_i$
  To decompress, use $"PCA"^(-1)(v_i) =U_k dot.c v_i + mu$
]

Simple recognition, compare in projected space, find nearest neighbour. Find face by computing reconstr. error and minimizing by varying patch pos. Compress data and visualization. Eigenfaces struggle with lighting differences. Fisherfaces improve this by maximizing between-class scatter, minimzing within-class scatter.

#colorbox(title: [PCA storage space], color: aqua)[
  Given $n$ images of size $x times y$, we want to store the dataset given a budget of $Z$ units of space. What is max number $K$ of princip. comp. allowed? \
  We need to store dataset mean $mu: x times y$, truncated eigenmat. $U_k: (x times y) times K$, compr. imgs. ${y_i}: n times K$
]


== JPG & JPEG
+ Convert RGB $->$ YUV (Y luminance / brightness, UV color / chrominance). Humans more sensitive to color, compress colors with chroma subsampling (e.g. color of upper left pixel for 4x4 grid)
+ Split image into 8x8 blocks for each YUV component, apply 2D DCT to it. 64 values, top left = low freq., bottom right = high freq. DCT: variant of DFT, fast implementation, only real values
+ Compress using int. devision with weighted matrix (Quantization table), compress bottom-right. Zig-zag run length encoding followed by Huffman.

Edges are softened because sharp edges require high freq. JPEG2000 improves by using Haar transform globally, not just on 8x8 blocks, on successively downsampled image (image pyramid)

*Image pyramids*: iter. applied approx. filter / downsampler. Gaussian pyramid, Laplacian is difference between 2 levels in Gaussian pyramid. \
*Haar transform*: Scaling capture info. at diff. freq., Translate captured info. at diff. loc. Can be represented by filter+downsample. Poor energy compaction.

== Optical flow
Apparent motion of brightness patterns. We set $u = (dif x) / (dif t)$, $v = (dif y) / (dif t)$, $I_x = (partial I) / (partial x)$, $I_y = (partial I) / (partial y)$, $I_t = (partial I) / (partial t)$

_Assuming_ *brightness constancy* (e.g. the observed object does not change its brightness): \
$ 
  I(x, y, t) &= I(x + u dot partial t, y + v dot partial t, t + partial t) \
             &approx I(x, y, t) + I_x u + I_y v + I_t = 0  quad (star)\
             &=> I_x u + I_y v + I_t approx 0 quad "(opt. flow const.)"
$

$(star)$ _Assuming_ *small motion* (e.g. small $(d x)/(d t) partial t, (d x)/(d t) partial t, partial t$, thus small motion per frame) using 1st-ord. Tailor series.

Aperture problem: 2 unknowns for every pixel $(u, v)$ but only one equation $=> oo$ solutions, opt. flow defines a line in $(u, v)$ space, compute normal flow. Need additional constraints to solve.

#colorbox(title: [Horn & Schunck algorithm])[
  Assumption: values $u(x, y)$, $v(x, y)$ are smooth and change slowly with $x, y$. Minimize $e_s + lambda e_c$ for $lambda > 0$ where

  $e_s = integral.double ((u_x^2 + x_y^2) + (v_x^2 + v_y^2)) dif x dif y$ (smooth.) \
  $e_c = integral.double (I_x u + I_y v + I_t)^2 dif x dif y$ (bright. const.)

  Coupled PDEs solved using iter. methods and finite diffs: $(partial u) / (partial t) = Delta u - lambda (I_x u + I_y v + I_t) I_x$ and  $(partial v) / (partial t) = Delta v- lambda (I_x u + I_y v + I_t) I_y$. Has errors at boundaries / information spreads from corner-type patterns.
]

#colorbox(title: [Lucas-Kanade])[
  Assumption: neighb. in $N times M$ patch $Omega$ have same motion $(u space v)^top$: _spatial coherence_, small mov., bright. const.$ inline(E = sum_(x, y in Omega) (I_x (x, y) u + I_y (x, y) v + I_t (x, y))^2) $
  
  $ inline(M U=mat(sum I_x^2, sum I_x I_y; sum I_x I_y, sum I_y^2) vec(u, v) = -vec(sum I_x I_t, sum I_y I_t)thick "("script(sum)" over patch "Omega")") $
  First compute $I_x, I_y, I_z$. Let $M = sum (nabla I) (nabla I)^T$ and $b = mat(-sum I_x I_t, -sum I_y I_t)$ Then at each pixel, compute $U$ by solving $M U = b$ by using least squares $U = M^(-1) b = (M^T M)^(-1) M^T b$. If $M$ singular / fails if all gradient vec. in same dir (along edge, smooth regions). Works with corners, textures. 
]

*Complexity:* Image $W times H$, Kernel $M times M$, with two conv/correlations: $cal(O)(W H M^2)$, if separable due to just 1D conv/correlations: $cal(O)(W H dot 2M)=cal(O)(W H M)$.

#colorbox(title: [Iterative refinement])[
  Estimate OF with Lucas-Kanade. Warp image using estimate OF. Estimate OF using warped image. Refine by repeating and add up all estimates. Fails if intensity structure  poor / large mov.
]
Gradient method fails when intensity structure within window is poor, displacement large etc.
#colorbox(title: [Coarse-to-fine estimation])[
  Create levels by gradual subsampling. Start at coarsest level, estimate OF, iterate and add until reached finest level. 
]
Still fails if large lighting changes happen.

#colorbox(title: [Affine motion])[each pixel provides 1 lin. constr., 6 global unknowns. Solve LSE. From bright. const. eq.:
  $ I_x (a_1 + a_2 x + a_3 y) + I_y (a_4 + a_5 x + a_6 y) + I_t approx 0 $
]

*SSD tracking*: Large displacements, extract template around pixel, match within search area, use correlation, choose best match. \
*Bayesian Optical flow*: Some low-level human motion illusions can be explained by adding an uncertainty model to LK. E.g. bright. const. with noise.

== Video compression
Visual perception $<24 "Hz"$. Flicker $>60 "Hz"$ in periphery. *Bloch's law*: if stimulus duration $<= 100 "ms"$, duration and brightness exchangeable. If brightness is halved, double duration. This enforces $>10 "Hz"$ for videos.

Interlaced video format: 2 temporally shifted half images (in bands) increases frequency, reduces spatial resolution. Full image repr. is progressive.

#colorbox(title: [Video compression with temporal redundancy], inline: false)[
  Predict current frame based on previously coded frames. Introducing 3 types of coded frames:
  + I-frame: Intra-coded frame, coded independently
  + P-frame: Predictively-coded based on previously coded frames (e.g. motion vec. + changes)
  + B-frame: Bi-directionally predicted frame, based on both previous and future frames.
]
Inefficient for many scene changes or high motion. 

#colorbox(title: [Motion-compensated prediction], color: black)[
  partition video into moving objects -- generally pretty difficult. Practical: *block-matching motion est.*: partition each frame into blocks, describe motion of block / find best matching block in reference frame. No obj. det., good perf. Can be sped up with 3 step log search, and improve precision with half-pixel motions. We encode the residual error (with JPG). Motion vector field (set of motion vec. for each block in frame) is easy to encode, fast, simple, periodic.
]

*MPEG Group of Pictures (GOP)* starts with I-frame, ends with B- ("open") or P-frame ("closed")

== CNN and Radon Transform
Given input $x$, learning target $y$, loss function $cal(L)$ compute kernel weights $theta$ using prediction $f(x, theta)$: $arg min_theta cal(L)(y, f(x, theta))$. Linear classifier $f(x, theta) = W x + b$ where $theta = {W, b}$. Use activation func. $phi.alt$ (sigmoid, *ReLU*, tanh, ...) to introduce non-linearity. Use gradient descent and back propagation (recursive appl. of chain rule to compute gradients) to find $theta$. Transformers, GANs, stable diffusion etc enable modern VC breakthroughs.

Classification: $f(x_1, theta)$ as score, take class with larger score. With $y_i in NN, s_i = f(x_i, theta)$, we get loss function: $cal(L)(y, f(x, theta)) = - sum_(i = 1)^N log (exp(s_(i, y_i)) / (sum_j exp(s_(i, j))))$

Regression: $f(x_1, theta)$ as value, can be used for classification by comparing value. With $y_i in RR^n, s_i = f(x_i, theta)$, we get: $cal(L)(y, f(x, theta)) = sum_(i = 1)^N norm(y_i - s_i)^2$

#colorbox(title: [Radon transform], color: black)[
  Given object with unknown density $f(x, y)$. Using the inverse of the RT we can find..... X-Ray along line $L$ at distance $s$ has intensity $I(s)$, travelling $partial s$ reduces intens. by $partial I$. reduction depends on intens. and optical density $u(s)$: $(partial I) / I(s) = -u(s) partial s$. Radon transform of $f(x, y)$: $R f(L) = integral_L f(x) |dif x|$. With $(x, y) = (rho cos theta - s sin theta, rho sin theta + s cos theta)$ we get:
  $R(rho, theta) = integral u(x, y) dif s$. We now want to find $u(x, y)$ given $R(rho, theta)$.
]
The continuous case of a radon transform of a line is:
$ R(rho, theta) = integral_(-oo)^infinity integral_(-infinity)^infinity u(x, y) delta(rho - x cos theta - y sin theta) partial x partial y $

*Properties of RT*: Linear, shifting input shifts the RT, rotating input rotates RT, RT of 2D convolution is 1D convolution of RT with respect to $rho$ ($R(f *_"2D" g) = R(f) *_"1D" R(g)$, RHS with fixed $theta$)

#image("src/radon-back-projection.png")

*Back projection*: Given RT, find $u(x, y)$ \
Fourier slice thm (apply with all proj. angles $theta$):
+ Measure protection (attenuation) data
+ 1D FT of projection data
+ 2D inverse FT and sum with previous image (backpropagate)
Requires precise attn. meas., sensitive to noise, unstable, hear to implem., blurring in final image. Add high-pass filter in Fourier domain after 2nd step.

*MLP* (2lrs):  
$text("Params") = H dot W dot N + D dot N$\
_(N: Hidden layers size, D: Output Dimension)_

*CNN* (2lrs):  
$text("Params") = (K dot N) + N + (K dot N dot D) + D$  \
_($K$: \# Kernel entries, N: Intermediate feature map activations, D: Output feature map activations)_  
Advantages: 
- *Spatial Hierarchies:* CNNs capture local patterns and spat. hierarch. (e.g., edges to textures to objects).
- *Parameter Efficiency:* Fewer parameters due to shared weights in convolutional layers.
- *Translation Invariance:* CNNs are robust to shifts in the image due to pooling and convolution.

= Computer graphics
== Graphics pipeline

#colorbox[
  + Modeling transform - from object to world-space
  + Viewing transform - from world to camera-space
  + Primitive processing - output primitives from transformed vertecies
  + 3D clipping - remove primitives outside frustum
  + Projection to screen-space
  + Scan conversion - Discretize continuous primitives, interpolate attributes at covered samples
  + Lighting, shading, texturing - compute colors
  + Occlusion handling - update color (e.g. z-buffers)
  + Display
]

Contemporary pipeline: CPU, Vector processing (per-vertex ops, transforms, lighting flow control), Rasterization, Fragment processing (per-fragment ops, shading, texturing, blending), Display. \
_Vertex shader_ 
*in:* global constants, per-vertex attributes, *out:* vertex color, vertex position\
_Fragment shader_ *in*: global constants, interpolated pixel color, *out:* pixel color
== Light & Colors
#grid(columns: 2, gutter: 1em,
image("src/ciergb.png", height: 12em),
[Light is mixture of many wavelengths. Consider $P(lambda)$ as intensity at wavelength $lambda$. Humans project inf. dimens. to 3D color (RGB). CIE experiment: some colors are not comb. of RGB. (neg. red needed)])


#colorbox(title: [Color spaces], inline: false)[
  - *RGB* (useful for displays, RGB colors specified)
  - *CIE XYZ*: Change of basis to avoid neg. comp. // todo add formula
  - *CIE xyY*: Chomaticity (color) $(x, y)$ derived by normalizing XYZ color components: \ $x = X / (X + Y + Z), y = Y / (X + Y + Z)$, ($Y=Y$ is brightness) \ Inversely: $X=x Y/y$, $Z=(1-x-y)Y/y$, $Y=Y$
  - *CIE RGB*: (435.8, 546.1, 700.0nm). Linear combination span triangle, the Color Gamut.
  - *CMY*: inverse (subtr.) to RGB. CMY = 1 - RGB.
  - *YIQ*: Luminance Y, In-phase I (orange-blue), Quadrature Q (purple-green). $ vec(Y, I, Q) = mat(0.299, 0.587, 0.114; 0.596, -0.275, -0.321; 0.212, -0.523, 0.311) vec(R, G, B) $
  - *HSV*: hue (base color), saturation (purity of color), value / lightness / brightness (intuitive)
  - *CIELAB / CIELUV*: Correct CIE chart colors to adjust for perceived "distance" betw. colors, nonlinear warp. MacAdams ellipses nearly circular.
]

#colorbox(color: aqua)[
  $ vec(x, y, z) = mat(x_R C_R, x_G C_G, x_B C_B; y_R C_R, y_G C_G, y_B C_B; (1 - x_R - y_R) C_R, (1 - x_G - y_G) C_G, (1 - x_B - y_B) C_B) vec(R, G, B)$
  Set $(R, G, B) = (1, 1, 1)$. Map to given white point (e.g. $(0.9505, 1, 1.0890)$)), then find $C_R, C_G, C_B$.
]

== Transformations
Change position & orientation of objects, project to screen, animating objects, ...

*Homogeneous coordinates* can represent affine maps (translation) with mat.-mul. Add dimension, project vertices $mat(x, y, z, w)^T$ onto $mat(x / w, y / w, z / w, 1)^T$.

#colorbox(color: black)[
  #grid(columns: (auto, auto, auto, auto), column-gutter: (0em, 1em, 0em), row-gutter: 0.8em,
    [Trans.], $mat(1, 0, 0, t_x; 0, 1, 0, t_y; 0, 0, 1, t_z; 0, 0, 0, 1)$,
    [Scale], $mat(s_x, 0, 0, 0; 0, s_y, 0, 0; 0, 0, s_z, 0; 0, 0, 0, 1)$,
    [Rot. \ x], $mat(1, 0, 0, 0; 0, cos theta, -sin theta, 0; 0, sin theta, cos theta, 0; 0, 0, 0, 1)$,
    [Rot. \ y], $mat(cos theta, 0, sin theta, 0; 0, 0, 1, 0; -sin theta, 0, cos theta, 0; 0, 0, 0, 1)$,
    [Rot. \ z], $mat(cos theta, -sin theta, 0, 0; sin theta, cos theta, 0, 0; 0, 0, 1, 0; 0, 0, 0, 1)$,
    [Shear \ x], $mat(1, "sh"_x^y, "sh"_x^z, 0; 
    "sh"_y^x, 1, "sh"_y^z, 0; 
    "sh"_z^x, "sh"_z^y, 1, 0; 
    0, 0, 0, 1)$,
    [Rot \ (2D)], $mat(cos theta, -sin theta, 0; sin theta, cos theta, 0; 0, 0, 1)$,
    [Shear \ (2D)], $mat(1, "sh"_x, 0; "sh"_y, 1, 0; 0, 0, 1)$,
    [Flip \ x], $mat(-1, 0, 0; 0, 1, 0; 0, 0, 1)$,
    grid.cell(
      colspan: 2,
      text([$"sh"_a^b$: Shear $a$-axis in terms of $b$, e.g. combine 
      $"sh"_x^z$ and $"sh"_y^z$ to shear $x y$-plane in terms of $
      z$]),
    ),
  )
]
Rigid transforms: translation, rotation. Linear: Rotation, Scaling, Shear. Projective: Rigid + Linear + Persp. + Paral. Note: $2 times 2$ matrices cannot express translations

*Commutativity* ($M_1 M_2 = M_2 M_1$) holds for: Translations, Rotations (2D),  Scaling, Scaling vs Rotation

#colorbox(title: [Change of coord. system], color: teal, inline: false)[
  #grid(columns: (10em, auto),
    image("src/change-coords.png"),
    $ p' = underbrace(mat(bold(r_0), bold(r_2), bold(r_3), bold(t); 0, 0, 0, 1), bold(M)) mat(p_x; p_y; p_z; 1) $
  )
  
  Transforming a normal: $bold(n') = (bold(M)^(-1))^T bold(n)$
]
Projecting $x$ on $n$: $"proj"_n(x)= (x dot n)/(n dot n) n$ \
Projections: parallel projection vs perspective.
#grid(columns: (auto, auto), column-gutter: 1em,
  $bold(M_"per") = mat(1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0; 0, 0, 1 / d, 0)$,
  $bold(M_"ort") = mat(1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1)$
)

#colorbox(title: [Quaternions], color: teal)[
  Alternative approach for rotation. Similar to $CC$, define $i^2 = j^2 = k^2 = - 1$, $i j k = -1$, $i j = k$, $j i = -k$, $j k = i$, $k j = -i$, $k i = j$, $i k = -j$. For $q = a + b i + c j + d k$, we have \ 
  - $norm(q) = sqrt(a^2 + b^2 + c^2 + d^2)$
  - $overline(z) = a - b i - c j - d k$ and $z^(-1) = overline(z) slash.big norm(z)$
]
Rotating a point $p = mat(x, y, z)^T$ around axis $u = mat(u_1, u_2, u_3)$ by angle $theta$.
+ Convert $p$ to quaternion $p_Q = x i + y j + z k$
+ Convert $q$ to quaternion $q'' = u_1 i + u_2 j + u_3 k$, normalize $q' = q'' slash.big norm(q'')$
+ Rotate quaternion $q = cos theta / 2 + q' sin theta / 2$ and $q^(-1) = cos theta / 2 - q' sin theta / 2$
+ Rotated point $p' = q p q^(-1)$. Convert to cartesian.

== Lighting & Shading
Lighting: Modelling physical interactions between materials and light sources \
Shading: Process of determining color of pixel.\
Pinhole pointing along $Z$ axis: $x=(f X)/Z$
$ inline((d x)/(d t) = f(Z V_x - X V_z)/Z^2\, delta x = f delta t (Z V_x - X V_z)/Z^2 "(V is veloc./deriv.)") $
Note: Pinhole camera measures radiance

#colorbox(title: [Basic quanitities of radiometry], inline: false)[
  *Flux*: $Phi(A)$ total amount of energy passing through surface or space per unit time $["J " / "s " = "W "]$ \
  *Luminous flux*: $integral P(lambda) V(lambda) dif lambda$. Perceived power of light weighted by human sensitiv. $["lumen"]$ \
  *Irradiance*: $E(x) = (dif Phi(A)) / (dif A(x))$ flux per unit area arriving at surface $["W " / "m "^2]$. \
  *Radiosity*: $B(x) = (dif Phi(A)) / (dif A(x))$ flux per unit area leaving a surface $["W " / "m "^2]$ \
  *Radient / Luminous Intensity*: $I(arrow(omega)) = (dif Phi) / (dif arrow(omega))$ outgoing flux per solid angle $["W " / "sr"]$. $Phi = integral_(S^2) I(arrow(omega)) dif arrow(omega)$\
  *Radiance*: $L(x, arrow(omega)) = (dif I(arrow(omega))) / (dif A(x)) = (dif^2 Phi(A)) / (dif arrow(omega) dif A(x) cos theta)$ flux per solid angle per perp. area = intensity per unit area
]

*Lamberts cosine law*: Irradiance at surface is proportional to cosine of angle of incident light and surface normal: $E = (Phi slash.big A) cos theta$\
*Bidir. reflectance distr. func.* (BRDF): relation between incident radiance and diff. refl. radiance. \
$f_r (x, arrow(omega)_i, arrow(omega)_r) = (dif L_r (x, arrow(omega)_r)) / (dif E_i (x arrow(omega)_i)) = (dif L_r (x, arrow(omega)_r)) / (L_i (x, arrow(omega)_i) cos theta_i dif arrow(omega)_i)$ \
*Reflection equation*: reflected radiance due to incident illumination from all directions (from BRDF): $integral_(H^2) f_r (x, arrow(omega)_i, arrow(omega)_r) L_i (x, arrow(omega)_i) cos theta_i d arrow(omega)_i = L_r (x, arrow(omega)_r)$ \
*Types of reflections*: Exact comp. is slow $->$ Specular, ideal diffuse, glossy specular, retro-reflective. \
*Attenuation*: $f_"att" = 1 / d_L^2$ due to spatial radiation.

#colorbox(title: [Phong Illumination Model], inline: false)[
  Approximate specular reflection by cosine powers
    $ I_lambda = underbrace(I_a_lambda k_a O_d_lambda, "Ambient") + f_"att" I_(p_lambda) \[underbrace(k_d O_(d_lambda)(N dot.c L), "Diffuse") + underbrace(k_s (bold(R) dot.c bold(V))^n, "Specular")\] $
  

  $h_i$ own emission coefficient, $I_a$ ambient light intensity, $k_a$ ambient light coefficient, $I_p$ directed light source intensity, $k_d$ diffuse reflection coefficient, $theta in [0, pi / 2]$ angle surface normal $N$ and light source vector $L$, attenuation factor $f_"att"$, $O_(d lambda)$ value of spectrum of object color at the point $lambda$.

  $k_a, k_d, k_s, n$ are material dependent constants.
]

== Shading models

Flat shading: one color per primitive

#colorbox(title: [Gouraud Shading], color: gray)[
  Lin.interpol. vertex intensities
  
  + Calculate face normals
  + Calculate vertex normals by averaging _(weighted by angle)_
  + Evaluate illumination model for each vertex
  + Interpolate vertex colors bilinearly: For each $y$ the scan line first interp. the color at the scanline/triangle-edge interesection linearly (by $y$), which we then use to interp. all pixels inbetween by $x$.
  Problems with scan line interpolation are perspective distortion, orientation dependence, shared vertices. Quality depends on size of primitives.
]

#colorbox(title: [Phong Shading], color: gray)[
  Get $bold(R)$ by reflecting the light vec. $bold(L)$ ar. the normal $bold(N)$: 
  $ bold(R) = 2(N dot L)N-L quad "with only"dot"as dot product" $

  Barycentric interpolation of normals on triangles.
  #image("src/phong-shading.png")
  Properties:
    Lagrange: $x = a => n_x = n_a$ \
    Partition of unity: $lambda_a + lambda_b + lambda_c = 1$ \
    Reproduction: $lambda_a dot.c a + lambda_b dot.c b + lambda_c dot.c c = x$.

  Problems: normal not defined / representative.\ 
  
]

Baryc. coord. of point $q$ is $lambda$ s.t. 
$lambda_1 p_1 + lambda_2 p_2 + lambda_3 p_3=q$

Flat, Gouraud in screen space, Phong in obj. space

*Transparency*: (2 obj., $P_1$ & $P_2$). Perceived intensity $I_lambda = I'_lambda_1 + I'_lambda_2$ where $I'_lambda_1$ is emission of $P_1$ and $I'_lambda_2$ is intensity filtered by $P_1$. We model it as follows: $I_lambda = I_(lambda_1) alpha_1 Delta t + I_(lambda_2) e^(-alpha_1 Delta t)$ where $alpha$ absorption, $Delta t$ thickness. Linearization: $I_lambda = I_lambda_1 alpha_1 Delta t + I_lambda_2 (1 - alpha_1 Delta t)$. If last object, set $Delta t = 1$. 
 Usually: $alpha_A  A + (1-alpha_A)alpha_B B$
 \ Problem: rendering order, sorted traversal of polygons and back-to-front rendering. \

*Back-to-front* order not always clear (as it could be in the both in front and back of another object, resort to depth peeling, multiple passes, each pass renders next closest fragment.


== Geometry and textures
Considerations: Storage, acquisition of shapes, creation of shapes, editing shapes, rendering shapes.\
*Explicit repr.* can easily model complex shapes and sample points, but take lots of storage:  
  - *Subdivision surfaces*, define surfaces by primitives, use recursive algorithm for refining  
  - *Point set surfaces*, store points as surface  
  - *Polygonal meshes*, explicit set of vertices with position, possibly with additional information. Intersection of polygons: either empty, vertex, edge  
  - *Parametric surfaces*, represent points as functions of parameters \((u, v)\), e.g., \((x, y, z) = f(u, v)\).  

*Implicit repr.* easily test inside / outside, compact storage, but sampling expensive, hard to model:
- *Implicit surfaces*, surface: zeros of a function
- *Level set*, a function that is zero on the surface
- *Fractals*, self-similar, recursive, infinite detail

*Manifolds*: Each edge is shared by at most two faces; the surface is connected and locally looks like a plane. \

*Mesh data structures*: Locations, how vertices are connected, attributes such as normals, color etc. Must support rendering, geometry queries, modifications. E.g.
- Triangle list (list of coord. and list of indices to that coord. list where every 3 elements repr. a triangle).
- Indexed Face set (array of vertices + list of indices, e.g. OBJ, OFF, WRL, costly queries, modifications)

#colorbox(title: [Texture mapping])[
  Enhance details without additional geom. complexity. Map Texture $(u, v)$ coords to geom. $(x, y, z)$ coords. Issues: aliasing, level-of-detail, (e.g. *sphere mapping*: $(u, v) -> (sin u sin v, cos v, cos u sin v)$). We want low-distortion, bijective mapping, efficiency.
]
*Bandlimiting*: Restrict amplitude of spectrum to zero for frequency beyond cut-off frequency. \

Anti-aliasing filters: 
- Gaussian (low-pass, separable). Closer pixels have higher weight
- Sinc $S_omega_c (x, y) = (omega_c sinc((omega_c x) / pi)) / pi times (omega_c sinc((omega_c y) / pi)) / pi$ ideal low-pass filter, IIR filter. $omega_c$ cutoff freq. Hard to implement, has infinite impulse respons.
- B-Spline: Allow for locally adaptive smoothing, adapt size of kernel to signal chars.

Magnification: for pixels mapping to area larger than pixel (jaggies), use bilinear interpolation.

*Mipmapping*: Store texture at multiple resolutions, choose based on projected size of triangle (far away $->$ lower res). Avoids aliasing, improves efficiency, storage overhead.
Uses at most $sum_(k=1)^infinity (1/4)^k = 1/3$ the storage.

*Supersampling*: Multiple color samples per pixel, final color is average - different patterns of samples possible (uniform, jittering, stochastic, Poisson).

#colorbox(color: black, inline: false)[
  *Light map*: Simulate effect of local light source. Can be pre-computed and dynamically adapted \
  *Environment map*: Mirror environment with imaginary sphere or cube for reflective objects \
  *Bump map*: Perturb surface normal according to texture, represents small-scale geometry. No bumps on silhouette, no self-occlusions, no self-shadowing. \
  *Displacement map*: Directly modifies the geometry by offsetting vertices based on texture. Fixes bump map issues, but more computationally expensive. 
]

*Procedural texture*: Generate texture from noise (Perlin, Gabor) from Guassian pyramid of noise and summing layers with weights.

*Perspective interpolation* in world-space can yield non-linear variation in screen-space. Optimal resampling filter is hence spatially variant.

#image("src/image.png")

== Scan conversion (rasterization)
Generate discrete pixel values. \
*Supersampling*: Sample in uniform grid, calcualte percentage and choose color multiplied by percentage. \
*Bresenham* line: choose closest pixel at each intersection. Fast decision, criterion based on midpoint $m$ and intersection point $q$. After computing first value $d$, we only need addition, bitshifts. $d_"new" = d_"old" + a$
#image("src/bresenham-line.png")

*Scan conversion of polygons*:
+ Calculate intersections on scan line
+ Sort intersection points by ascending x-coords.
+ Fill spans between two consecutive intersection points if parity in interval is odd (so inside)

== Bézier Curves & Splines
#colorbox(title: [Bézier Curves])[
  $bold(x)(t) = bold(b)_0 B_0^n (t) + ... + bold(b)_n B_n^n (t)$ \ where $B_i^n$ are the Bernstein polyn. ($binom(n, i) = (n!) / (i! (n- i)!)$): \
  $B_i^n (t) = binom(n, i) t^i (1 - t)^(n - i) "if" i != 0 "else" 0$ \
  (partition of unity, pos. definite, recursion, symmetry). \
  Coefficients $bold(b)_0, ..., bold(b)_n$ are called control- / Bézier-points, together define the control polygon.

  *Degree* is highest order of polyn., order is deg. + 1. Bézier-Curves have *affine invariance* (affine transf. of curve accompl. by affine transf. of control pts.). Curve lies in *convex hull* of control polygon $"conv"(P) := {sum_(i = 1)^n lambda_i bold(p)_i | lambda_i >= 0, sum_(i = 1)^n lambda_i = 1}$. Control polyg. gives *rough sketch* of curve. Since $B_0^n (0) = B_n^n (1) = 1$, *interpol. endpoints* $bold(b)_0, bold(b)_n$. *Max. number of intersect*. of line with curve is $<=$ number of intersect. with control polygon.
  Note: Bézier curves are special cases of B-spline
]

Disadvantages: global support of basis functions (change one point, change entire curve), new control pts yields higher degree, $C^r$ continuity between segments of Bézier-Curves (deriving $r$ times .

// TODO Casteljau?
Interpolate points $bold(p)_0, ..., bold(p)_n$ using basis fcts.

#colorbox(title: [B-Spline functions])[
  B-Spline curve $bold(s)(u)$ built from piecewise polyn. bases $s(u) = sum_(i = 0)^k bold(d)_i N_i^n (u)$ \
  Coefficients $bold(d)_i$ are called "de Boor" pts. Bases are piecewise, recursively def. polyn. over sequence of knots $u_0 < u_1 < u_2 < ...$ defined by knot vec. $T = bold(u) = mat(u_0, ..., u_(k + n + 1))$

  Partition of unity $sum_i N_i^n (u) equiv 1$, positivity $N_i^n(u) >= 0$, compact support $N_i^n(u) = 0$, $forall u in.not [u_i, u_(i + n + 1)]$, continuity $N_i^n$ is $(n - 1)$ times cont. differentiable.

  $ inline(N_i^n (u) = (u - u_i) dot (N_i^(n-1)(u) / (u_(i+n) - u_i)) \ + (u_(i+n+1) - u) dot (N_(i+1)^(n-1)(u) / (u_(i+n+1) - u_(i+1)))) $
  Examples with $n = 1$ and $n=2$:
  $ N_i^1(u) = cases(
    (u - u_i) / (u_(i+1) - u_i) "if" u in [u_i, u_(i+1)],
  (u_(i+2) - u) / (u_(i+2) - u_(i+1)) "if" u in [u_(i+1), u_(i+2)]), quad N_i^2(u) = \ inline((u - u_i) dot (N_i^1(u) / (u_(i+2) - u_i))  + (u_(i+3) - u) dot (N_(i+1)^1(u) / (u_(i+3) - u_(i+1)))) $
]

== Subdivision surfaces

Generalization of spline curves / surfaces allowing arbitrary control meshes using successive refinement (subdivision), converging to smooth limit surfaces, connecting splines and meshes. \
*Interpolating:* new points are an interpolation of control points _vs_ *Approximating:* controls points are moved, and new points are added inbetween.\
*Primal:* faces are split _vs_ *Dual:* vertices are split \
#grid(columns: 2, column-gutter: -0.5em, align: horizon,
  image("src/loop-subdivision.png", height: 6.8em),
  [*Loop Subdivision*\
    $ inline(E_i = (3/8) dot (d_1 + d_i) + (1/8) dot (d_(i - 1) + d_(i + 1))) \ 
inline(d_1' = alpha_n dot d_1 + (1 - alpha_n) / n dot sum_(j = 2)^(n + 1)(d_j)) \ inline(alpha_n = 3/8 + (3/8 + 1/(4n) cos(2pi))^2) $]
)

#grid(columns: (6.5em, auto), column-gutter: 0.5em, align: horizon,
  grid.cell(align: right, image("src/doo-sabin-subdivision.png", height: 6em)),
  [ *Doo-Sabin Subdivision* \
    $ inline(V_2 = 1/n sum_(j=1)^n d_j\, E_i=1/2 (d_1 + d_(2i)))$
$ inline(d_(1\,j)'=1/4(d_1+E_j+E_(j-1)+V_j)) $]
)



== Visibility and shadows
*Painter's algorithm*: Render objects from furthest to nearest. Issues with cyclic overlaps &intersec. \
*Z-Buffer*: store depth to nearest obj for each px. Initialize to $oo$, then iter. over polygons and update z-buffer. Limited resolution, non-linear, place far from camera \
*Planar shadows*: draw projection of obj. on ground. No self-shadows, no shadows on other objects, curved surfaces. \
*Projective texture shadows*: Separate obstacles and receivers, compute b/w img. of of obst. from light, use as projective textrue. Need to specify obstacle & receiver, no self-shadows. \
#colorbox(title: [Shadow maps])[
  Compute depths from light & camera. For each px, get world coords, project to light plane, compare $d(x_L)$ (dist. light → projected point) to $z_L$ (dist. light → $x_L$). If $d(x_L) < z_L$, $x$ is in shadow. Add bias: $d(x_L) + b < z_L$ to prevent self-shadowing. Use cubical shadow map or spotlights if shadow point is out of view. Filter depth test to reduce aliasing.
]
*Shadow volumes*: Count shadow volume boundary crossings along a ray—if > 0, the polygon is shadowed. Use silhouette edges to optimize, but this adds geometry and increases rasterization cost. Objects must be watertight with precise rasterization.


== Ray Tracing
#colorbox()[
  Send rays into scene to determine color of px. On obj. hit, send mult. rays (diffused, reflected, refracted) further until we hit light source, or reach some amount of bounces. Figure out whether point in shadow by shooting rays to all light sources. For anti-aliasing, use mult. rays per px. (Pipel.: Ray Generation, Intersection, Shading)
]
*Ray-surface intersections*: Ray equation $bold(r)(t) = bold(o) + t bold(d)$. For the following, solve for $t$ and then put get position with ray equ.
*Plane:* $0=bold(n) dot (bold(o)+t bold(d)) - c$
*Sphere*: $norm(bold(o) + t bold(d) - bold(c))^2 - r^2 = 0$. 
*Triangle*: Barycentric coords. $bold(x) = s_1 bold(p)_1 + s_2 bold(p)_2 + s_3 bold(p)_3$. Intersect: $(bold(o) + t bold(d) - bold(p)_1) dot.c n = 0$. Using the following: $bold(n) = (bold(p)_2 - bold(p)_1) times (bold(p)_3 - bold(p)_1)$ we get $t = - ((bold(o) - bold(p)_1) dot.c bold(n)) / (bold(d) dot.c bold(n))$. Now compute the coeffs. $bold(s)_i$. Test whether $s_1 + s_2 + s_3 = 1$ and $0 <= s_i <= 1$. If so, inside triangle.

*Ray-tracing shading extensions*: Refraction, mult. lights, area lights for soft shadows, motion blur (sample objs, intersect in time), depth of field \
*Cost*: $O(N_x N_y N_o) = "#px" dot.c "#objects"$

*Accelerate*: Accelerate with less intersections, introduce uniform grids or space partitioning trees. \
*Uniform grids*: Divide space into cells, test ray against cells, then against objects in cell. \
*Space partitioning trees*: octree, kd-tree, bsp-tree
*Corner Cutting:* Insert vertices at $1/4$, $3/4$ of each edge, remove old vertecies, connect them and repeat.
#image("src/corner-cutting.png")

*deCasteljau*: Compute a triangular representation, successively interpolate, "corner cutting":
  #grid(columns: 2, column-gutter: 0.5cm, [
    #table(
      columns: 4,
      rows: 4,
      stroke: none,
      [$b_0$], [], [], [],
      [$b_1$], [$b_0^1$], [], [],
      [$b_2$], [$b_1^1$], [$b_0^2$], [],
      [$b_3$], [$b_2^1$], [$b_1^2$], [$b_0^3$]
    )
  ], [
    Consider the three control points $b_0, b_1, b_2$:
    
    $
    b_0^1(t) = (1 - t)b_0 + t b_1\
    b_1^1(t) = (1 - t)b_1 + t b_2\
    b_0^2(t) = (1 - t)b_0^1(t) + t b_1^1(t)
    $
  ])

  *deBoor algorithm*: generalizes deCasteljau, evaluate B-spline of degree $n$ at $u$, set $d_i^0 = d_i$, finally $d_0^n = s(u)$
$
d_i^k = (1 - a_i^k) d_(i)^(k-1) + a_i^k d_(i+1)^(k-1), space space space a_i^k = (u-u_(i+k-1))/(u_(i+n) - u_(i+k-1))
$
Note that $a_i^k$ vanishes outside of $[u_(i+k-1), u_(i+n)]$!

```python
d_i = [d[j + i - n] for j in range(0, n + 1)]  
for k in range(1, n + 1):
  for j in range(n, k - 1, -1):
    a_i_k = (u - u_knots[j + i - n]) / (u_knots[j + i + 1 - k] - u_knots[j + i - n])
    d_i[j] = (1.0 - a_i_k) * d_i[j - 1] + a_i_k * d_i[j]
return d_i[n]  # This is d_0^n = s(u)
```