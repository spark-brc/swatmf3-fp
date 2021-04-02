      subroutine rtday

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine routes the daily flow through the reach using a 
!!    variable storage coefficient

!!    ~ ~ ~ INCOMING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    ch_d(:)     |m             |average depth of main channel
!!    ch_k(2,:)   |mm/hr         |effective hydraulic conductivity of
!!                               |main channel alluvium
!!    ch_l2(:)    |km            |length of main channel
!!    ch_n(2,:)   |none          |Manning's "n" value for the main channel
!!    ch_s(2,:)   |m/m           |average slope of main channel
!!    ch_w(2,:)   |m             |average width of main channel
!!    chside(:)   |none          |change in horizontal distance per unit
!!                               |change in vertical distance on channel side
!!                               |slopes; always set to 2 (slope=1/2)
!!    evrch       |none          |Reach evaporation adjustment factor.
!!                               |Evaporation from the reach is multiplied by
!!                               |EVRCH. This variable was created to limit the
!!                               |evaporation predicted in arid regions.
!!    inum1       |none          |reach number
!!    inum2       |none          |inflow hydrograph storage location number
!!    pet_day     |mm H2O        |potential evapotranspiration
!!    phi(1,:)    |m^2           |cross-sectional area of flow in channel at
!!                               |bankfull depth
!!    phi(6,:)    |m             |bottom width of main channel
!!    rnum1       |none          |fraction of overland flow
!!    rchstor(:)   |m^3 H2O       |water stored in reach
!!    varoute(2,:)|m^3 H2O       |water flowing into reach on day
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ OUTGOING VARIABLES ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    rcharea     |m^2           |cross-sectional area of flow
!!    rchdep      |m             |depth of flow on day
!!    rtevp       |m^3 H2O       |evaporation from reach on day
!!    rttime      |hr            |reach travel time
!!    rttlc       |m^3 H2O       |transmission losses from reach on day
!!    rtwtr       |m^3 H2O       |water leaving reach on day
!!    sdti        |m^3/s         |average flow on day in reach
!!    rchstor(:)   |m^3 H2O       |water stored in reach
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ LOCAL DEFINITIONS ~ ~ ~
!!    name        |units         |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    det         |hr            |time step (24 hours)
!!    c           |none          |inverse of channel side slope
!!    jrch        |none          |reach number
!!    p           |m             |wetted perimeter
!!    rh          |m             |hydraulic radius
!!    scoef       |none          |Storage coefficient (fraction of water in 
!!                               |reach flowing out on day)
!!    topw        |m             |top width of main channel
!!    vol         |m^3 H2O       |volume of water in reach at beginning of
!!                               |day
!!    wtrin       |m^3 H2O       |amount of water flowing into reach on day
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

!!    ~ ~ ~ SUBROUTINES/FUNCTIONS CALLED ~ ~ ~
!!    Intrinsic: Sqrt, Min
!!    SWAT: Qman

!!    ~ ~ ~ ~ ~ ~ END SPECIFICATIONS ~ ~ ~ ~ ~ ~
!!    Modified by Balaji Narasimhan
!!    Spatial Sciences Laboratory, Texas A&M University
      use parm

      integer :: jrch
      real :: wtrin, scoef, p, tbase, topw, vol, c, rh
      real :: volrt, maxrt, adddep, addp, addarea, vc, aaa,rttimefp
	real :: rttlc1, rttlc2, rtevp1, rtevp2, det,fpdep,vcfp,ch_rto,scoeffp
      real :: fpsdti, fpp

      fpsdti = 0.
      fpdep = 0.
      fpinf=0.
      
      jrch = inum1

				
      wtrin = varoute(2,inum2) * (1. - rnum1)
      !if(jrch==88.and.iida==3) then
      !   jrch=inum1
      !endif
      
!! calculate volume of water in reach
      vol = 0.
      vol = wtrin + rchstor(jrch)

!! Find average flowrate in a day
      volrt = vol / 86400.

!! Find maximum flow capacity of the channel at bank full
      c = 0.
      c = chside(jrch)
	p = phi(6,jrch) + 2. * ch_d(jrch) * Sqrt(1. + c * c)
	rh = phi(1,jrch) / p
	maxrt = Qman(phi(1,jrch), rh, ch_n(2,jrch), ch_s(2,jrch))

      sdti = 0.
	rchdep = 0.
	p = 0.
	rh = 0.
	vc = 0.

!! If average flowrate is greater than than the channel capacity at bank full
!! then simulate flood plain flow else simulate the regular channel flow
      if (volrt > maxrt) then
	  fpsdti = 0
					  
													   
					   
			   
	  adddep = 0

											 
															 
        Do While (fpsdti < volrt-maxrt)
          adddep = adddep + 0.01
          addarea = fpwth(jrch) * adddep
          addp = fpwth(jrch) + 2. * adddep 
          !addp = p + (ch_w(2,jrch) * 4) + 2. * adddep * Sqrt(1. + 4 * 4)
	    rh = addarea / addp
          fpsdti = Qman(addarea, rh, ch_n(2,jrch), ch_s(2,jrch))
        end do
	  fpsdti=volrt-maxrt
        !flood plain infiltration
        fpinf = (24. * uhalpha * ch_k(2,jrch) * ch_l2(jrch) * 
     &   (fpwth(jrch) - ch_w(2,jrch))) / 86400. !m3/s
        if (fpinf>fpsdti) then
           fpinf = fpsdti
           fpsdti = 0.
        else
           fpsdti = fpsdti - fpinf
        endif
        
        volrt = volrt - fpinf

        fpsdti = 0
        adddep=0.
        rcharea=0.
        if (volrt>maxrt) then
	     adddep = 0
	     Do While (fpsdti < volrt-maxrt)
             adddep = adddep + 0.01
             addarea = fpwth(jrch) * adddep
             addp = fpwth(jrch) + 2. * adddep 
	       rh = addarea / addp
             fpsdti = Qman(addarea, rh, ch_n(2,jrch), ch_s(2,jrch))
           end do
           fparea = addarea
           fpdep = adddep !water depth in the floodplain, m 
	     fpp = addp
	     fpsdti = volrt-maxrt
           sdti = maxrt
        else
           sdti = 0
           adddep = 0.
	     Do While (sdti < volrt)
             adddep = adddep + 0.01
             addarea = fpwth(jrch) * adddep
             addp = fpwth(jrch) + 2. * adddep 
	       rh = addarea / addp
             sdti = Qman(addarea, rh, ch_n(2,jrch), ch_s(2,jrch))
           end do
           fparea = 0
           fpdep = 0 !water depth in the floodplain, m 
	     fpp = 0
	     fpsdti = 0
           sdti = volrt
        endif   
        rcharea = phi(1,jrch)
        rchdep = ch_d(jrch)
      else
	!! find the crossectional area and depth for volrt
	!! by iteration method at 1cm interval depth
	!! find the depth until the discharge rate is equal to volrt
	  sdti=0.
        rchdep=0.
        Do While (sdti < volrt)
	    rchdep = rchdep + 0.01
	    rcharea = (phi(6,jrch) + c * rchdep) * rchdep
	    p = phi(6,jrch) + 2. * rchdep * Sqrt(1. + c * c)
	    rh = rcharea / p
          sdti = Qman(rcharea, rh, ch_n(2,jrch), ch_s(2,jrch))
	  end do
	  sdti = volrt
	end if

!! calculate top width of channel at water level
      topw = 0.
      if (rchdep+fpdep <= ch_d(jrch)) then
        topw = phi(6,jrch) + 2. * rchdep * c
      else
        topw = fpwth(jrch)
        !topw = 5 * ch_w(2,jrch) + 2. * (rchdep - ch_d(jrch)) * 4.
      end if

!!	Time step of simulation (in hour)
        det = 24.

      if (sdti>0.and.volrt <= maxrt) then
        !! calculate velocity and travel time
        vc = sdti / rcharea  
        vel_chan(jrch) = vc
	  rttime = ch_l2(jrch) * 1000. / (3600. * vc)


        !! calculate volume of water leaving reach on day
        scoef = 0.
 	  rtwtr = 0.
        scoef =  det / (rttime + det)
        if (scoef > 1.) scoef = 1.

        rtwtr = scoef * (wtrin + rchstor(jrch) - fpinf*86400.)

        !! calculate amount of water in channel at end of day
        rchstor(jrch) = rchstor(jrch) + wtrin - rtwtr - fpinf*86400.
        !! Add if statement to keep rchstor from becoming negative
        if (rchstor(jrch) < 0.0) rchstor(jrch) = 0.0

        !! transmission and evaporation losses are proportionally taken from the 
        !! channel storage and from volume flowing out

        !! calculate transmission losses
	  rttlc(jrch) = 0.

	  if (rtwtr > 0.) then

	!!  Total time in hours to clear the water

 	    p = phi(6,jrch) + 2. * ch_d(jrch) * Sqrt(1. + c * c)
          rttlc(jrch) = det * ch_k(2,jrch) * ch_l2(jrch) * p
          rttlc2 = rttlc(jrch) * rchstor(jrch) / (rtwtr + rchstor(jrch))

	    if (rchstor(jrch) <= rttlc2) then
	      rttlc2 = min(rttlc2, rchstor(jrch))
	      rchstor(jrch) = rchstor(jrch) - rttlc2
	      rttlc1 = rttlc(jrch) - rttlc2
	      if (rtwtr <= rttlc1) then
	        rttlc1 = min(rttlc1, rtwtr)
	        rtwtr = rtwtr - rttlc1
	      else
	        rtwtr = rtwtr - rttlc1
	      end if
	    else
	      rchstor(jrch) = rchstor(jrch) - rttlc2
	      rttlc1 = rttlc(jrch) - rttlc2
	      if (rtwtr <= rttlc1) then
	        rttlc1 = min(rttlc1, rtwtr)
	        rtwtr = rtwtr - rttlc1
	      else
	        rtwtr = rtwtr - rttlc1
	      end if
	    end if
	  rttlc(jrch) = rttlc1 + rttlc2
        end if


        !! calculate evaporation
	  rtevp = 0.
        if (rtwtr > 0.) then

          aaa = evrch * pet_day / 1000.

	    if (rchdep <= ch_d(jrch)) then
            rtevp = aaa * ch_l2(jrch) * 1000. * topw
	    else
		  if (aaa <=  (rchdep - ch_d(jrch))) then
              rtevp = aaa * ch_l2(jrch) * 1000. * topw
	      else
	        rtevp = (rchdep - ch_d(jrch)) 
	        rtevp = rtevp + (aaa - (rchdep - ch_d(jrch))) 
              topw = phi(6,jrch) + 2. * ch_d(jrch) * c           
	        rtevp = rtevp * ch_l2(jrch) * 1000. * topw
	      end if
	    end if

	    rtevp2 = rtevp * rchstor(jrch) / (rtwtr + rchstor(jrch))

	    if (rchstor(jrch) <= rtevp2) then
	      rtevp2 = min(rtevp2, rchstor(jrch))
	      rchstor(jrch) = rchstor(jrch) - rtevp2
	      rtevp1 = rtevp - rtevp2
	      if (rtwtr <= rtevp1) then
	        rtevp1 = min(rtevp1, rtwtr)
	        rtwtr = rtwtr - rtevp1
	      else
	        rtwtr = rtwtr - rtevp1
	      end if
	    else
	      rchstor(jrch) = rchstor(jrch) - rtevp2
	      rtevp1 = rtevp - rtevp2
	      if (rtwtr <= rtevp1) then
	        rtevp1 = min(rtevp1, rtwtr)
	        rtwtr = rtwtr - rtevp1
	      else
	        rtwtr = rtwtr - rtevp1
	      end if
	    end if
	  rtevp = rtevp1 + rtevp2
        end if

      elseif (volrt > maxrt) then
        !! floodplain flow condition
        
        !-----------------------------------------   
        !! Main channel velocity and travel time
        !-----------------------------------------
        vc = maxrt / phi(1,jrch)  
        vel_chan(jrch) = vc
	  rttime = ch_l2(jrch) * 1000. / (3600. * vc)
        
        !-----------------------------------------   
        !! Floodplain flow velocity and travel time
        !-----------------------------------------
        vcfp = fpsdti / (fpwth(jrch) * fpdep)  !m/s
	  rttimefp = ch_l2(jrch) * 1000. / (3600. * vcfp)


        !! calculate volume of water leaving reach on day
        scoef =  det / (rttime + det)
        scoeffp = det / (rttimefp + det)
        if (scoef > 1.) scoef = 1.
        if (scoeffp > 1.) scoeffp = 1.
        
        rtwtr = scoef * (maxrt*86400.)  + scoeffp * (fpsdti*86400.) 

        !! calculate amount of water in channel at end of day
        rchstor(jrch) = rchstor(jrch) + wtrin - rtwtr - fpinf*86400.
        !! Add if statement to keep rchstor from becoming negative
        if (rchstor(jrch) < 0.0) rchstor(jrch) = 0.0

        !! transmission and evaporation losses are proportionally taken from the 
        !! channel storage and from volume flowing out

        !! calculate transmission losses
	  rttlc(jrch) = 0.

	  if (rtwtr > 0.) then

	!!  Total time in hours to clear the water

 	    p = phi(6,jrch) + 2. * ch_d(jrch) * Sqrt(1. + c * c)
          rttlc(jrch) = det * ch_k(2,jrch) * ch_l2(jrch) * p
          rttlc2 = rttlc(jrch) * rchstor(jrch) / (rtwtr + rchstor(jrch))

	    if (rchstor(jrch) <= rttlc2) then
	      rttlc2 = min(rttlc2, rchstor(jrch))
	      rchstor(jrch) = rchstor(jrch) - rttlc2
	      rttlc1 = rttlc(jrch) - rttlc2
	      if (rtwtr <= rttlc1) then
	        rttlc1 = min(rttlc1, rtwtr)
	        rtwtr = rtwtr - rttlc1
	      else
	        rtwtr = rtwtr - rttlc1
	      end if
	    else
	      rchstor(jrch) = rchstor(jrch) - rttlc2
	      rttlc1 = rttlc(jrch) - rttlc2
	      if (rtwtr <= rttlc1) then
	        rttlc1 = min(rttlc1, rtwtr)
	        rtwtr = rtwtr - rttlc1
	      else
	        rtwtr = rtwtr - rttlc1
	      end if
	    end if
	  rttlc(jrch) = rttlc1 + rttlc2 
        end if


        !! calculate evaporation
	  rtevp = 0.
       if (rtwtr > 0.) then

          aaa = evrch * pet_day / 1000.

	    if (rchdep+fpdep <= ch_d(jrch)) then
            rtevp = aaa * ch_l2(jrch) * 1000. * topw
	    else
		  if (aaa <=fpdep) then
              rtevp = aaa * ch_l2(jrch) * 1000. * topw
	      else
	        rtevp = fpdep * ch_l2(jrch) * 1000. * topw + (aaa - fpdep) * ch_l2(jrch) * 1000. * ch_w(2,jrch)
	      end if
	    end if

	    rtevp2 = rtevp * rchstor(jrch) / (rtwtr + rchstor(jrch))

	    if (rchstor(jrch) <= rtevp2) then
	      rtevp2 = min(rtevp2, rchstor(jrch))
	      rchstor(jrch) = rchstor(jrch) - rtevp2
	      rtevp1 = rtevp - rtevp2
	      if (rtwtr <= rtevp1) then
	        rtevp1 = min(rtevp1, rtwtr)
	        rtwtr = rtwtr - rtevp1
	      else
	        rtwtr = rtwtr - rtevp1
	      end if
	    else
	      rchstor(jrch) = rchstor(jrch) - rtevp2
	      rtevp1 = rtevp - rtevp2
	      if (rtwtr <= rtevp1) then
	        rtevp1 = min(rtevp1, rtwtr)
	        rtwtr = rtwtr - rtevp1
	      else
	        rtwtr = rtwtr - rtevp1
	      end if
	    end if
	  rtevp = rtevp1 + rtevp2
        end if
          

      else
        rtwtr = 0.
        sdti = 0.
	  rchstor(jrch) = 0.
	  vel_chan(jrch) = 0.
        flwin(jrch) = 0.
        flwout(jrch) = 0.
      end if

!! precipitation on reach is not calculated because area of HRUs 
!! in subbasin sums up to entire subbasin area (including channel
!! area) so precipitation is accounted for in subbasin loop

!!      volinprev(jrch) = wtrin
!!	qoutprev(jrch) = rtwtr

      if (rtwtr < 0.) rtwtr = 0.
      if (rchstor(jrch) < 0.) rchstor(jrch) = 0.

      if (rchstor(jrch) < 10.) then
        rtwtr = rtwtr + rchstor(jrch)
        rchstor(jrch) = 0.
      end if
     !! if(rtwtr>100.) then
     !!    write(*,'(2i5,20f5.2)') iida,jrch,rtwtr/vol,scoef*sdti*86400./vol,scoeffp*fpsdti*86400./vol,rchstor(jrch)/vol,rttlc/vol,
     !!&    fpinf*86400./vol,rtevp/vol,(rtwtr+rchstor(jrch)+rttlc+fpinf*86400.+rtevp)/vol
     !!    vol=vol
     !! endif
      
      return
      end