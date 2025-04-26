------**PLC点位表**------
--X1	启动-右			AuxDI1
--X2	左感应器1		AuxDI2
--X3	左感应器2		AuxDI3
--X4	左感应器3		AuxDI4
--X5	右感应器1		AuxDI5
--X6	右感应器2		AuxDI6
--X7	右感应器3		AuxDI7
--Y0	三色灯-绿		AuxDO0
--Y1	三色灯-黄		AuxDO1
--Y2	三色灯-红		AuxDO2
--Y3	蜂鸣器			AuxDO3
--Y4	真空吸气		AuxDO4
--Y5	刹车		    AuxDO5
--X0	启动-左			AuxDI0
--Y10	真空压1			AuxDI8
--Y11	真空压2			AuxDI9

------**动作位置**------
-- PTP(CSafe,100,-1,0) --工作原点
-- PTP(CSafe,100,-1,0)--中间过度点
-- PTP(CleftSafe1,100,-1,0)--左安全点
-- PTP(CrightSafe1,100,-1,0)-- 右安全位置

-- PTP(取料上,100,-1,0) --取料点上
-- PTP(取料点下,100,-1,0)--取料点下
-- PTP(取料点,100,-1,0)--取料点

-- PTP(LeftBigBox1,100,-1,0)--左工位1点
-- PTP(大箱子左工位2点,100,-1,0)	--左工位2点
-- PTP(大箱子左工位3点,100,-1,0)	--左工位3点

-- PTP(RightBigBox1,100,-1,0)	--右工位1点
-- PTP(大箱子右工位2点,100,-1,0)	--右工位2点
-- PTP(大箱子右工位3点,100,-1,0)	--右工位3点

------**拓展轴位置**------
--  EXT_AXIS_PTP(0,zero,100) --拓展轴零点
--  EXT_AXIS_PTP(0,EXUP1,100) --拓展轴抬升上方

------**控制点表**------
-- SetAuxDO(4,1,0,0) 		--吸气开
-- SetAuxDO(4,0,0,0)		--吸气关
-- SetAuxDO(5,1,0,0)		--刹车开
-- SetAuxDO(5,0,0,0)		--刹车关

------**变量表**------
--reset	复位状态
--safeH 安全高度

--**主程序**--
	--**加载UDP协议**--
	ExtDevSetUDPComParam("192.168.57.88", 2021, 2)
-- 	ExtDevSetUDPComParam("192.168.57.88", 2021, 2, 50, 2, 100, 1, 50, 20)
	ExtDevLoadUDPDriver()
	reset =0 --复位
	safeH =800 --安全高度
	--**行，高，列**--	
	m = 0; n = 0; h = 0
	i = 3; j =3; k =2
	
	---**复位**---
	::CresetON::do--复位动作
	end
	--**初始化灯**--
    SetAuxDO(0,0,0,0)
    SetAuxDO(1,0,0,0)
    SetAuxDO(2,1,0,0)
    SetAuxDO(3,0,0,0)
    SetAuxDO(4,1,0,0)
    WaitMs(1000)
	--**机器人复位**--
	j1,j2,j3,j4,j5,j6 = GetActualJointPosDegree() --当前轴位姿
	x,y,z,a,b,c = GetActualTCPPose() --当前空间位姿
	toolNum = GetActualTCPNum() --当前应用的工具号
	if (type(z) == "number") then--转换数据类型
		ZL = safeH - z -- Z 抬到固定高度
		MoveL(j1,j2,j3,j4,j5,j6,x,y,z,a,b,c,toolNum,0,100,180,100,0,0.000,0.000,0.000,0.000,0,1,0,0,ZL,0,0,0) --运行Z向偏移
	end
	if (type(j1) == "number") then--转换数据类型
		RegisterVar("number","t1")
		if(j1 >0)then--左右复位安全位置分割线
-- 			PTP(CleftSafe1,20,-1,0)--左安全位置
			PTP(CSafe,20,-1,0) 	--工作原点
		end
		if(j1<0)then--右
-- 			PTP(CrightSafe1,20,-1,0)-- 右安全位置
			PTP(CSafe,20,-1,0) --工作原点
		end
	end		
    
	--**复位拓展轴**--
	ExtAxisServoOn(1,1) 			--拓展轴使能
	WaitMs(2000)
	SetAuxDO(5,1,0,0)				--释放刹车
	WaitMs(2000)
	EXT_AXIS_PTP(0,zero,100)		--拓展轴回零点

	
	--**设置状态灯**--
    SetAuxDO(1,1,0,0)
    SetAuxDO(2,0,0,0)
	reset = 1
	---**复位结束**---
	
	while(1)do
		---***获取IO***--- 
		leftsenser1 = 1  -- GetAuxDI(2,0)
		leftsenser2 = 1--GetAuxDI(3,0)
		leftsenser3 = 1-- GetAuxDI(4,0)
		rightsenser1 = 1--GetAuxDI(5,0)
		rightsenser2 = 1 --GetAuxDI(6,0)
		rightsenser3 = 1 --GetAuxDI(7,0)
		WaitMs(100) --等待

		---**右工位取左工位放启动**---
		if reset == 1 and (GetAuxDI(1,0)==1) then
		--if reset == 1 then
				if  leftsenser1 == 1 and leftsenser2 == 1 and leftsenser3 ==1 then
					SetAuxDO(0,1,0,0) --设置灯
					SetAuxDO(1,0,0,0)
					sleep_ms(200)
					--**码垛动作**--
					while(h<k) do
						while(n<j) do
							while(m<i) do
								xiqu = 0
								--右边取料
								PTP(CSafe,100,200,0)--中间过度点
								--RIGHT PICKUP
								X2 =  -411.929*m+0.755*n --右工位取
								Y2 =  -0.160*m+-304.293*n --右工位取
                                Z3 = 300*(k-h) + 40
                                Z4 = 300*(k-h-1) + 25
								::s2::do
								end
								PTP(RightBigBox1,200,-1,1,X2,Y2,Z3+30,0,0,0)
								Lin(RightBigBox1,100,-1,0,1,X2,Y2,Z4,0,0,0)
								SetAuxDO(4,0,0,0)
								sleep_ms(1200)
								Lin(RightBigBox1,100,-1,0,1,X2,Y2,Z3+30,0,0,0)
								--**吸取负压判断**-- 
							 --   if  xiqu < 3 and GetAuxDI(8,0) == 0  and GetAuxDI(9,0) == 0  then
								-- 	xiqu = xiqu + 1
								-- 	SetAuxDO(4,0,0,0)
								-- 	sleep_ms(1000)
								-- 	--goto s2--跳转到s1标签
								-- elseif xiqu >2 then
								-- 	Pause(2)
								-- 	xiqu = 0
								-- 	goto s2--跳转到s1标签
								-- end
								--取料结束
								EXT_AXIS_PTP(0,EXUP1,100) --拓展轴抬升上方
								PTP(CSafe,100,200,0)--中间过度点
								EXT_AXIS_PTP(0,zero,100)
								sleep_ms(200)
								--**码垛动作**--
								shifang = 0						
								X1 = -409.443*m+-4.077*n --左工位放
								Y1 = -3.286*m+304.389*n  --左工位放
                                Z1 = 300*(h+1)+40
                                Z2 = (300*h) + 25
								PTP(LeftBigBox1,100,200,1,X1-30,Y1+50,Z1+30,0,0,0)
								Lin(LeftBigBox1,100,-1,0,1,X1,Y1,Z2,0,0,0)
								SetAuxDO(4,1,0,0)
								WaitMs(1200)
								Lin(LeftBigBox1,100,-1,0,1,X1,Y1,Z1+30,0,0,0)
								PTP(CSafe,100,200,0)--中间过度点
								RegisterVar("number","m")
								RegisterVar("number","n")
								RegisterVar("number","h")
								m = m+1
								end
						n = n+1; m = 0
						end
					m = 0; n = 0
					h = h+1
					end
					SetAuxDO(0,0,0,0)
					SetAuxDO(1,1,0,0)
					SetAuxDO(3,1,0,0)
					sleep_ms(1000)
					SetAuxDO(3,0,0,0)	
				else -- 感应器未到位就报警3声
					sensererror = 0 
					while sensererror < 3 do
						SetAuxDO(3,1,0,0)
						sleep_ms(1000)
						SetAuxDO(3,0,0,0)
						sensererror = sensererror +1
					end
				end
	else
			end
		
			---**左工位结束**---


			---**左工位取右工位放**---
			if reset == 1 and (GetAuxDI(0,0)==1 ) then
				if rightsenser1 == 1 and rightsenser2 == 1 and rightsenser3 ==1  then
					SetAuxDO(0,1,0,0) --设置灯
					SetAuxDO(1,0,0,0)
					sleep_ms(200)
					--**码垛动作**--
					while(h<k) do
						while(n<j) do
							while(m<i) do
								xiqu = 0
								step = 8
								RegisterVar("number","step")
								--右边取料
								--LEFT PICKUP
								PTP(CSafe,100,200,0)--中间过度点
								X2 = -409.443*m+-4.077*n  --左工位取
								Y2 =  -3.286*m+304.389*n  --左工位取
                                Z3 = 300*(k-h)+40
                                Z4 = 300*(k-h-1) + 25		
                                ::s1::do
								end
								PTP(LeftBigBox1,200,-1,1,X2,Y2,Z3+30,0,0,0)
								sleep_ms(4000)
								Lin(LeftBigBox1,100,-1,0,1,X2,Y2,Z4,0,0,0)
								SetAuxDO(4,0,0,0)
								sleep_ms(1200)
								Lin(LeftBigBox1,100,-1,0,1,X2,Y2,Z3+30,0,0,0)
								--**吸取负压判断**-- 
								-- if  xiqu < 3 and GetAuxDI(8,0) == 0  and GetAuxDI(9,0) == 0  then
								-- 	xiqu = xiqu + 1
								-- 	SetAuxDO(4,0,0,0)
								-- 	sleep_ms(1000)
								-- 	--goto s1--跳转到s1标签
								-- elseif xiqu >2 then
								-- 	Pause(2)
								-- 	xiqu = 0
								-- 	goto s1--跳转到s1标签
								-- end
								--取料结束
								EXT_AXIS_PTP(0,EXUP1,100) --拓展轴抬升上方
								PTP(CSafe,100,200,0)--中间过度点
								EXT_AXIS_PTP(0,zero,100)
								sleep_ms(200)
								--**码垛动作**--
								shifang = 0
								step = 9
								RegisterVar("number","step")							
							    X1 =  -411.929*m+0.755*n --右工位放
								Y1 = -0.160*m+-304.293*n  --右工位放
                                Z1 = 300*(h+1)+40
                                Z2 = 300*h + 25
								PTP(RightBigBox1,100,200,1,X1-30,Y1-50,Z1+50,0,0,0)
								Lin(RightBigBox1,100,-1,0,1,X1,Y1,Z2,0,0,0)
								SetAuxDO(4,1,0,0)
								WaitMs(1200)
								Lin(RightBigBox1,100,-1,0,1,X1,Y1,Z1+50,0,0,0)
								PTP(CSafe,100,200,0)--中间过度点
								RegisterVar("number","m")
								RegisterVar("number","n")
								RegisterVar("number","h")
								m = m+1
								end
						n = n+1; m = 0
						end
					m = 0; n = 0
					h = h+1
					end
					SetAuxDO(0,0,0,0)
					SetAuxDO(1,1,0,0)
					SetAuxDO(3,1,0,0)
					sleep_ms(1000)
					SetAuxDO(3,0,0,0)	
				else -- 感应器未到位就报警3声
					sensererror = 0 
					while sensererror < 3 do
						SetAuxDO(3,1,0,0)
						sleep_ms(1000)
						SetAuxDO(3,0,0,0)
						sensererror = sensererror +1
					end
				end
				else
			end
			---**右工位结束**---
	m=0
	n=0
	h=0		
	end
--**主程序结束**--