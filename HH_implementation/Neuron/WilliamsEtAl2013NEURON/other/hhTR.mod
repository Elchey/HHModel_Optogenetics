TITLE hh.mod   squid sodium, potassium, and leak channels
 
COMMENT
Stochastic Hodgkin and Huxley equations with diffusion aproximation and a Truncation-Restoration procedure (hhTR)
DA equations as in Orio & Soudry (2012) PLoS One, Truncated-Restored algorithm from 
Huang et al. (2013) Phys Rev E 87:012716  DOI: 10.1103/PhysRevE.87.012716

Sodium channel states are:
mh0 = m0h0   mh1 = m1h0   mh2 = m2h0  mh3 = m3h0
mh4 = m0h1   mh5 = m1h1   mh6 = m2h1  mh7 = m3h1

Implemented for Pezo, Soudry and Orio (2014) Front Comp Neurosci 
 
ENDCOMMENT
 
UNITS {
	(mA) = (milliamp)
	(mV) = (millivolt)
	(S) = (siemens)
}
 
NEURON {
	SUFFIX hhTR
	USEION na READ ena WRITE ina
	USEION k READ ek WRITE ik
	NONSPECIFIC_CURRENT il
	RANGE gnabar, gkbar, gl, el, NNa, NK, sigmana, sigmak,se
}
 
PARAMETER {
	se = -1
	gnabar = .12 (S/cm2)	<0,1e9>
	gkbar = .036 (S/cm2)	<0,1e9>
	gl = .0003 (S/cm2)	<0,1e9>
	el = -54.3 (mV)
	NNa = 5000
	NK = 1500
	sigmak = 0.5
	sigmana = 0.4
}
 
ASSIGNED {
	v (mV)
	celsius (degC)
	ena (mV)
	ek (mV)
	dt (ms)
	ina (mA/cm2)
	ik (mA/cm2)
	il (mA/cm2)
	am	(/ms)
	ah	(/ms)
	an	(/ms)
	bm	(/ms)
	bh	(/ms)
	bn	(/ms)
	stsum
	M
	N
	H
	R[14]	(/ms)
	em[8]        :Error residuals (to be restored) for Na channels
	en[5]        : Error residuals (to be restored) for K channels
}
 
STATE {	
	mh0
	mh1
	mh2
	mh3
	mh4
	mh5
	mh6
	mh7
	n0
	n1
	n2
	n3
	n4
}

BREAKPOINT {
	SOLVE states METHOD euler
    : Euler method has to be used otherwise the /dt factor in the Derivative block
    : is not applied correctly
    
	ina = gnabar*mh7*(v - ena)
	ik = gkbar*n4*(v - ek)
	il = gl*(v - el)
}
 
INITIAL {
	rates(v)	
	if (se>0) {set_seed(se)}
	M=am/bm
	H=ah/bh
	N=an/bn
	stsum=(1+H)*(1+M)^3
	mh0=1/stsum
	mh1=3*M/stsum
	mh2=3*M^2/stsum
	mh3=M^3/stsum
	mh4=H/stsum
	mh5=H*3*M/stsum
	mh6=H*3*M^2/stsum
	mh7=H*M^3/stsum
	
	stsum=(1+N)^4
	n0=1/stsum
	n1=4*N/stsum
	n2=6*N^2/stsum
	n3=4*N^3/stsum
	n4=N^4/stsum
		
    : Set initial errors to 0
	FROM k=0 TO 7 {em[k]=0}
	FROM k=0 TO 4 {en[k]=0}
}

DERIVATIVE states {  
	rates(v)

	mh0' = (-3*am-ah)*mh0 + bm*mh1 + bh*mh4 + R[0]+R[3] + em[0]/dt
	mh1' = (-2*am-bm-ah)*mh1 + 3*am*mh0 + 2*bm*mh2 + bh*mh5 -R[0]+R[1]+R[4]	+ em[1]/dt
	mh2' = (-am-2*bm-ah)*mh2 + 2*am*mh1 + 3*bm*mh3 + bh*mh6 -R[1]+R[2]+R[5] + em[2]/dt
	mh3' = (-3*bm-ah)*mh3 + am*mh2 + bh*mh7 -R[2]+R[6] + em[3]/dt
	mh4' = (-3*am-bh)*mh4 + bm*mh5 + ah*mh0 + R[7]-R[3] + em[4]/dt
   	mh5' = (-2*am-bm-bh)*mh5 + 3*am*mh4 + 2*bm*mh6 + ah*mh1 -R[7]+R[8]-R[4] + em[5]/dt
   	mh6' = (-am-2*bm-bh)*mh6 + 2*am*mh5 + 3*bm*mh7 + ah*mh2 -R[8]+R[9]-R[5] + em[6]/dt
   	mh7' = (-3*bm-bh)*mh7 + am*mh6 + ah*mh3 -R[9]-R[6] + em[7]/dt
	
	n0' = -4*an*n0 + bn*n1 + R[10] + en[0]/dt
	n1' = (-3*an-bn)*n1 + 4*an*n0 + 2*bn*n2 - R[10] + R[11] + en[1]/dt
	n2' = (-2*an-2*bn)*n2 + 3*an*n1 + 3*bn*n3 -R[11] + R[12] + en[2]/dt
	n3' = (-an-3*bn)*n3 + 2*an*n2 + 4*bn*n4 -R[12] + R[13] + en[3]/dt
	n4' = -4*bn*n4 + an*n3 -R[13] + en[4]/dt

	mtrunca()
	ntrunca()
}
 
LOCAL q10

PROCEDURE mtrunca() { :Truncate Na states to maintain boundaries
	LOCAL MH[8], i, j, k, l, msum, msumN, ps, aux, aux2, pos, pos2[8], em_aux[8]
	UNITSOFF
	
	msum = mh0+mh1+mh2+mh3+mh4+mh5+mh6+mh7
	MH[0]=mh0/msum
	MH[1]=mh1/msum
	MH[2]=mh2/msum
	MH[3]=mh3/msum
	MH[4]=mh4/msum
	MH[5]=mh5/msum
	MH[6]=mh6/msum
	MH[7]=mh7/msum
	msumN=1	

	aux=0
	aux2=0
	l=0
	FROM i=0 TO 7 {
        :check if any state is greater than 1 (only one is possible)
		if (MH[i]>1) {
			aux=1
			pos = i
			VERBATIM
			break;
			ENDVERBATIM					
			}
        :check if any states are lower than 0 (can be more than 1)
		if (MH[i]<0) {
			aux=2
			pos2[l] = i
			l=l+1
			}
		}
	if (aux == 0) {  : No state was outside [0,1]
		FROM l=0 TO 7 {em[l]=0}
	}
	if (aux == 1) {  : a value greater than 1 was detected
		aux2 = MH[pos]
		FROM j=0 TO 7 { 
			em[j]=MH[j]  :the cut-off values are stored
			MH[j]=0      :All states are set to 0
			}
		em[pos]=aux2-1   
		MH[pos]=1        :The state greater than 1 is set to 1
	}
	if (aux == 2) {  : One or more values lower than 0 were detected
		FROM n = 0 TO (l-1) {
			ps=pos2[n]
			em_aux[n]=MH[ps]
			aux2=aux2+MH[ps]
			}
		FROM k = 0 TO 7 {
			em[k]=MH[k]*(1-1/(msumN-aux2))
			MH[k]=MH[k]/(msumN-aux2)
			}
		FROM n = 0 TO (l-1) {
			ps=pos2[n]
			em[ps]=em_aux[n]
			MH[ps]=0
			}
	}
	mh0=MH[0]
	mh1=MH[1]
	mh2=MH[2]
	mh3=MH[3]
	mh4=MH[4]
	mh5=MH[5]
	mh6=MH[6]
	mh7=MH[7]
	UNITSON
}

PROCEDURE ntrunca() { :Truncate potassium states. See the comments in mtrunca()
	LOCAL N[5], i, j, k, l, nsum, nsumN, ps, aux, aux2, pos, pos2[5], en_aux[5]
	UNITSOFF
	nsum = n0+n1+n2+n3+n4
	N[0]=n0/nsum
	N[1]=n1/nsum
	N[2]=n2/nsum
	N[3]=n3/nsum
	N[4]=n4/nsum

	nsumN = 1
	aux=0
	aux2=0
	l=0
	FROM i=0 TO 4 {
		if (N[i]>1) {
			aux=1
			pos = i
			VERBATIM
			break;
			ENDVERBATIM
			}
		if (N[i]<0) {
			aux=2
			pos2[l] = i
			l=l+1
			}
		}
	if (aux == 0) {
		FROM l=0 TO 4 {en[l]=0}
		}
	if (aux == 1) {
		aux2 = N[pos]
		FROM j=0 TO 4 {
			en[j]=N[j]
			N[j]=0
			}
		en[pos]=aux2-1
		N[pos]=1
	}
	if (aux == 2) {
		FROM n = 0 TO (l-1) {
			ps=pos2[n]
			en_aux[n]=N[ps]
			aux2=aux2+N[ps]
			}
		FROM k = 0 TO 4 {
			en[k]=N[k]*(1-1/(nsumN-aux2))
			N[k]=N[k]/(nsumN-aux2)
			}
		FROM n = 0 TO (l-1) {
			ps=pos2[n]
			en[ps]=en_aux[n]
			N[ps]=0
			}
	}

	n0=N[0]
	n1=N[1]
	n2=N[2]
	n3=N[3]
	n4=N[4]
	UNITSON
}

PROCEDURE rates(v(mV)) {  :Computes rate and other constants at current v.
	LOCAL q10
	UNITSOFF
	q10 = 3^((celsius - 6.3)/10)
	am = q10*0.1*(v+40)/(1-exp(-(v+40)/10))
	bm = q10*4*exp(-(v+65)/18)
	ah = q10*0.07*exp(-(v+65)/20) 
	bh = q10/(1+exp(-(v+35)/10))
	an = q10*0.01*(v+55)/(1-exp(-(v+55)/10))
	bn = q10*0.125*exp(-(v+65)/80)
		
	FROM ii=0 TO 9 {R[ii]=normrand(0,1/sqrt(NNa*dt))}
	FROM ii=10 TO 13 {R[ii]=normrand(0,1/sqrt(NK*dt))}
	R[0] = R[0]*sqrt(3*am*mh0+bm*mh1)
	R[1] = R[1]*sqrt(2*am*mh1+2*bm*mh2)
	R[2] = R[2]*sqrt(am*mh2+3*bm*mh3)
	R[3] = R[3]*sqrt(ah*mh0+bh*mh4)
	R[4] = R[4]*sqrt(ah*mh1+bh*mh5)
	R[5] = R[5]*sqrt(ah*mh2+bh*mh6)
	R[6] = R[6]*sqrt(ah*mh3+bh*mh7)
	R[7] = R[7]*sqrt(3*am*mh4+bm*mh5)
	R[8] = R[8]*sqrt(2*am*mh5+2*bm*mh6)
	R[9] = R[9]*sqrt(am*mh6+3*bm*mh7)
	R[10] = R[10]*sqrt(4*an*n0+bn*n1)
	R[11] = R[11]*sqrt(3*an*n1+2*bn*n2)
	R[12] = R[12]*sqrt(2*an*n2+3*bn*n3)
	R[13] = R[13]*sqrt(an*n3+4*bn*n4)
	UNITSON
}

