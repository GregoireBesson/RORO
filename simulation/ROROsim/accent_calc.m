function  state = accent_calc( roro )
%Function calculates the assent phase of the rocket
    global env;

   
    state_0 = [roro.X; roro.Q; roro.P; roro.L];
    tspan = [0,6];


    
    % Solve flight using ODE45
    [t, state]= ode45(@flight,tspan,state_0);

    % --------------------------------------------------------------------------
    %% Equations of motion discribed to be sloved in ode45 
    function state_dot = flight(t,state)
        
        
        X= state(1:3);
        Q= state(4:7);
        P= state(8:10);
        L= state(11:13);
        % Rotation matrix for transforming body coord to ground coord
        Rmatrix= quat2rotm(roro.Q');
        
        % Axis wrt earth coord
        YA = Rmatrix*env.YA0'; 
        PA = Rmatrix*env.PA0'; 
        RA = Rmatrix*env.RA0'; 
        CnXcp = roro.CnXcp;
        Cn= CnXcp(1);
        Xcp= CnXcp(2);
        %% -------Velocity-------
        Xdot=P./roro.Mass;
        
        %% -------Angular velocity--------- in quarternians 
        invIbody = roro.Ibody\eye(3); %inv(roro.Ibody); inverting matrix
        omega = Rmatrix*invIbody*Rmatrix'*L;
        s = Q(1);
        v =[Q(1); Q(2); Q(3)];
        sdot = 0.5*(dot(omega,v));
        vdot = 0.5*(s*omega + cross(omega,v));
        Qdot = [sdot; vdot];
        
        %% -------Angle of attack------- 
        % Angle between velocity vector of the CoP to the roll axis, given in the ground coord        
        % To Do : windmodel in env, 
        Vcm = Xdot  + env.W;
        Xstab = Xcp- roro.Xcm;
        if(Xstab < 0)
            warning('Rocket unstable');
        end
        omega_norm = omega/norm(omega); %normalized
        Xprep =Xstab*sin(acos(dot(RA,omega_norm))); % Prependicular distance between omaga and RA
        
        Vomega = Xprep *cross(RA,omega);
        
        V = Vcm + Vomega; % approxamating the velocity of the cop        
        
        Vmag = norm(V);
        Vnorm = V/Vmag;
        alpha = acos(dot(Vnorm,RA));
        
        %% Forces = rate of change of Momentums
        
        Fthrust = -roro.T*RA;
        
        Fg = [0 0 -roro.Mass*env.g]';
        
        % Axial Forces
        Famag = 0.5*env.rho*Vmag^2*roro.A_ref*roro.Cd; % To DO: make axial 
        
        Fa = -Famag*RA;
        
        % Normal Forces
        Fnmag = 0.5*env.rho*Vmag^2*roro.A_ref*Cn;
        
        RA_Vplane = cross(RA,Vnorm);
        Fn = Fnmag*(cross(RA,RA_Vplane));
        
        Ftot = Fthrust + Fg + Fa + Fn;
        %% Torque
        Trqn = Fnmag*Xstab*(RA_Vplane); 
        
        %Tqm=(Cda1*omega)*omegaax2; rotational torque by motor
%         r_f = %TODO
%         Trmag = 0.5*env.rho*V^2*roro.A_ref*roro.Cld*r_f;
%         Tr = Trmag*RA;
        Trq = Trqn;
        
        
        state_dot =[Xdot; Qdot; Ftot;Trq];
        
        
    end
end
 