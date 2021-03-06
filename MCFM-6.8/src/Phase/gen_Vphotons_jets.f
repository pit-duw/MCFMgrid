      subroutine gen_Vphotons_jets(r,nphots,njets,p,wt,*)
c---- generate phase space for 2-->2+nphots+njets process
c----   with (34) being a vector boson
c----   and 5,..,4+nphots the photons
c----   and 5+nphots,..,4+nphots+njets the jets
c----
c---- This routine is adapted from gen_njets.f
c----
c---- r(mxdim),p1(4),p2(4) are inputs reversed in sign 
c---- from physical values 
c---- phase space for -p1-p2 --> p3+p4+p5+p6
c---- with all 2 pi's (ie 1/(2*pi)^(4+2n))
c----
c---- if 'nodecay' is true, then the vector boson decay into massless
c---- particles is not included and 2 less integration variables
c---- are required
      implicit none
      include 'constants.f'
      include 'mxdim.f'
      include 'limits.f'
      include 'xmin.f'
      include 'nodecay.f'
      include 'leptcuts.f'
      include 'reset.f'
      include 'breit.f'
      include 'part.f'
      include 'process.f'
      include 'ipsgen.f'
      double precision r(mxdim),rdk1,rdk2,mflatsq
      double precision p(mxpart,4),p3(4),p34(4),psumjet(4),pcm(4),Q(4)
      double precision wt,dot,s345,s346
      double precision hmin,hmax,delh,h,sqrts,pt,etamax,etamin,xx(2)
      double precision y,sinhy,coshy,phi,mv2,wtbw,mjets
      double precision ybar,ptsumjet2,ycm,sumpst,q0st,rshat
      double precision costh,sinth,dely,xjac
      double precision ptjetmin,etajetmin,etajetmax,pbreak
      double precision ptmin_part,etamax_part,pbreak_part
      double precision plstar,estar,plstarsq,y5starmax,y5starmin
      integer j,nu,nphots,njets,nphotsjets,ijet
      logical first,xxerror,flatreal
      common/energy/sqrts
      common/x1x2/xx
      parameter(flatreal=.false.)
      data first/.true./,xxerror/.false./
      save first,ptjetmin,etajetmin,etajetmax,pbreak,xxerror
      
      if (first .or. reset) then
        first=.false.
        reset=.false.
        call read_jetcuts(ptjetmin,etajetmin,etajetmax)
        if (part .eq. 'real') then
c--- if we're generating phase space for real emissions, then we need
c--- to produce partons spanning the whole phase space pt>0,eta<10;
c--- in this case, pbreak=ptjetmin simply means that we
c--- generate pt approx. 1/x for pt > pbreak and
c--- pt approx. uniformly for pt < pbreak
c          pbreak=ptjetmin
c          ptjetmin=0d0
          etajetmax=20d0
        else
c--- for lord and virt, the partons produced here can be generated
c--- right up to the jet cut boundaries and there is no need for pbreak
          pbreak=0d0
        endif
c--- in case this routine is used for very small values of ptjetmin
        if ((ptjetmin .lt. 5d0) .and. (part .ne. 'real')) pbreak=5d0
c--- for processes in which it is safe to jet ptmin to zero at NLO
      if ((part .eq. 'real') .and. (pbreak .lt. 1d-8)) pbreak=5d0
      endif        


c--- total number of photons and jets
      nphotsjets=nphots+njets

      do nu=1,4
        do j=1,4+nphotsjets
          p(j,nu)=0d0
        enddo
        Q(nu)=0d0 
        psumjet(nu)=0d0
        pcm(nu)=0d0
      enddo 

      wt=2d0*pi
                       
      do ijet=1,nphotsjets
c--- generate the pt of jet number ijet
c--- rapidity limited by E=pT*coshy
        wt=wt/16d0/pi**3
c        xmin=2d0/sqrts
c        xmax=1d0/ptjetmin

        if (ijet .le. nphots) then
          if     (nphots .eq. 3) then
            ptmin_part=min(gammpt,gammpt2,gammpt3)
          elseif (nphots .eq. 2) then
            ptmin_part=min(gammpt,gammpt2)
          elseif (nphots .eq. 1) then
            ptmin_part=gammpt
          else
            write(6,*) 'Unexpected # photons in gen_Vphotons_jets: ',
     &                  nphots
            stop
          endif
          etamax_part=gammrapmax
c          pbreak_part=0d0
          if (part .eq. 'real') then
c--- cannot generate exactly to match, since dipoles transform photon
          etamax_part=20d0
c          ptmin_part=0d0
c          pbreak_part=gammpt
          endif
        else
          ptmin_part=ptjetmin
          etamax_part=etajetmax
c          pbreak_part=pbreak
        endif

c        if ((flatreal) .and. (part .eq. 'real')) then
cc--- generate flat pt for the real contribution
c          pt=r(ijet)*((sqrts/2d0)-ptmin_part)+ptmin_part
c          wt=wt*((sqrts/2d0)-ptmin_part)*pt
c        else
cc--- favour small pt region 
c          hmin=1d0/dsqrt((sqrts/2d0)**2+pbreak_part**2)
c          hmax=1d0/dsqrt(ptmin_part**2+pbreak_part**2)
c          delh=hmax-hmin
c          h=hmin+r(ijet)*delh        
c          pt=dsqrt(1d0/h**2-pbreak_part**2)
c          wt=wt*delh/h**3
c        endif

        if (part .eq. 'real') then
          call genpt(r(ijet),ptmin_part,.false.,pt,xjac)
        else
          call genpt(r(ijet),ptmin_part,.true.,pt,xjac)
        endif
        wt=wt*xjac
 
        etamax=sqrts/2d0/pt
        if (etamax**2 .le. 1d0) then
          write(6,*) 'etamax**2 .le. 1d0 in gen_phots_jets.f',etamax**2 
          wt=0d0
          return 1
        endif
        etamax=dlog(etamax+dsqrt(etamax**2-1d0))
        
        etamax=min(etamax,etamax_part)
        y=etamax*(2d0*r(nphotsjets+ijet)-1d0)
        wt=wt*2d0*etamax
        
        sinhy=dsinh(y)
        coshy=dsqrt(1d0+sinhy**2)
        
        p(4+ijet,4)=pt*coshy
        
        phi=2d0*pi*r(2*nphotsjets+ijet)
        wt=wt*2d0*pi
        
        p(4+ijet,1)=pt*dcos(phi)
        p(4+ijet,2)=pt*dsin(phi)
        p(4+ijet,3)=pt*sinhy
        
        do nu=1,4
          psumjet(nu)=psumjet(nu)+p(4+ijet,nu)
        enddo
      enddo
      

c      if (case .eq. 'W_2gam') then
cc--- this modified version of the Breit-Wigner form allows for some fraction of
cc--- events to be generated more efficiently below mflatsq
cc--- [currently used only for W+2 photons]
c        if (gammpt .gt. mass3) then
c           mflatsq=wsqmin
c        else
c          mflatsq=(mass3-gammpt/2d0)**2
c          if (mflatsq .lt. wsqmin) mflatsq=wsqmin
c        endif
c        call breitw_mod(r(3*nphotsjets+1),wsqmin,wsqmax,
c     &                  mflatsq,mass3,width3,mv2,wtbw)
c      else
c--- [currently used only for everything else]
c--- now generate Breit-Wigner        
        call breitw(r(3*nphotsjets+1),wsqmin,wsqmax,
     &              mass3,width3,mv2,wtbw)
c      endif
      wt=wt*wtbw/2d0/pi
c--- invariant mass of jets
      mjets=psumjet(4)**2-psumjet(1)**2-psumjet(2)**2-psumjet(3)**2
      mjets=dsqrt(dabs(mjets))
      
      ybar=0.5d0*dlog((psumjet(4)+psumjet(3))/(psumjet(4)-psumjet(3)))
      ptsumjet2=psumjet(1)**2+psumjet(2)**2
      plstarsq=((sqrts**2-mv2-mjets**2)**2
     . -4d0*(mjets**2*mv2+ptsumjet2*sqrts**2))/(4d0*sqrts**2)
      if (plstarsq .le. 0d0) then
        wt=0d0
        return 1
      endif
      plstar=dsqrt(plstarsq)
      Estar=dsqrt(plstarsq+ptsumjet2+mjets**2)
      y5starmax=0.5d0*dlog((Estar+plstar)/(Estar-plstar))
      y5starmin=-y5starmax

      etamax=ybar-y5starmin
      etamin=ybar-y5starmax
      dely=etamax-etamin
      ycm=etamin+r(3*nphotsjets+2)*dely     
      sinhy=dsinh(ycm)
      coshy=dsqrt(1d0+sinhy**2)
      
c--- now make the initial state momenta
      sumpst=ptsumjet2+(psumjet(3)*coshy-psumjet(4)*sinhy)**2
      q0st=dsqrt(mv2+sumpst)
      rshat=q0st+dsqrt(mjets**2+sumpst)
      pcm(4)=rshat*coshy
      pcm(3)=rshat*sinhy
            
      xx(1)=(pcm(4)+pcm(3))/sqrts
      xx(2)=(pcm(4)-pcm(3))/sqrts
      
      if   ((xx(1)*xx(2) .gt. 1d0) .and. (xxerror .eqv. .false.)) then
        xxerror=.true.
        write(6,*) 'gen_njets: xx(1)*xx(2),xx(1),xx(2)',
     .   xx(1)*xx(2),xx(1),xx(2)  
      endif

      if   ((xx(1) .gt. 1d0) .or. (xx(2) .gt. 1d0)
     & .or. (xx(1) .lt. xmin).or. (xx(2) .lt. xmin)) then
         wt=0d0
         return 1
      endif 
      
      wt=wt*dely
      do j=1,4
        Q(j)=pcm(j)-psumjet(j)
      enddo
      
      p(1,4)=-xx(1)*sqrts/2d0
      p(1,3)=p(1,4)
      p(2,4)=-xx(2)*sqrts/2d0
      p(2,3)=-p(2,4)
      
      wt=wt*rshat/(sqrts**2*q0st)
      
c--- dummy values if there's no decay
      if (nodecay) then
        rdk1=0.5d0
        rdk2=0.5d0
      else
        rdk1=r(3*nphotsjets+3)
        rdk2=r(3*nphotsjets+4)
      endif
      
c--- decay boson into leptons, in boson rest frame
      costh=2d0*rdk1-1d0
      sinth=dsqrt(1d0-costh**2)
      phi=2d0*pi*rdk2
      p34(4)=dsqrt(mv2)/2d0
      p34(1)=p34(4)*sinth*dcos(phi)
      p34(2)=p34(4)*sinth*dsin(phi)
      p34(3)=p34(4)*costh
      
c--- boost into lab frame    
      call boost(dsqrt(mv2),Q,p34,p3)
      do j=1,4
      p(3,j)=p3(j)
      p(4,j)=Q(j)-p(3,j)
      enddo

c--- veto PS regions for W+2 photons
c      if (case .eq. 'W_2gam') then
c        if (ipsgen .eq. 1) then
c          s345=2d0*(dot(p,3,4)+dot(p,3,5)+dot(p,4,5))
c          if (abs(sqrt(s345)-mass3) .lt. 5d0*width3) return 1
c          s346=2d0*(dot(p,3,4)+dot(p,3,6)+dot(p,4,6))
c          if (abs(sqrt(s346)-mass3) .lt. 5d0*width3) return 1
c        endif
c      endif

      wt=wt/8d0/pi
            
      return
      end
      
      
      
      
      
      
      
      
      
      
      
