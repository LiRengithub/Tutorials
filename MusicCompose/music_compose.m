%合成音乐
clear sound;%关闭已有的音乐
clear;%清空工作区
close all;%关闭图像
clc;%清空命令行

%<<<<<<<<-----------------------------------------------------------
%---本段代码无实际意义，仅用于标定拍长
%---以一个四分音符为一拍时，拍长pattime=0.5s
%note2=0:T:2*pattime;%二分音符
%note4=0:T:pattime;%四分音符
%note8=0:T:0.5*pattime;%八分音符
%----------------------------------------------------------->>>>>>>>

%<<<<<<<<-----------------------------------------------------------
%本段代码无实际意义，仅用以纪念十二平均律
%key=zeros(1,12);%用于存储一个8度内每个键的音调频率
%wave=zeros(12,length(note4));
%Y=[];
%for i=1:12
%    key(i)=f0*K^(i-1);
%    wave(i,:)=sin(2*pi*key(i)*note4);
%    Y=[Y wave(i,:)];
%end
%----------------------------------------------------------->>>>>>>>


Play(M_library(2));%播放乐库中第2首歌

function play=Play(MtP)
%音乐播放函数
%输入参数为(3*n)的数组MtP 待播放音乐Music to Play
%返回值为播放该音乐所需的时间，单位s
freq=8192;%采样频率
T=1/freq;%采样周期
pattime=0.5;%一拍时间，以四分音符为一拍
f0=349.23;%Hz F调 
K=2^(1/12);%以十二平均律为标准，相邻半音的频率之商

%harmonic_wave 谐波矩阵，对每个音调取相应行向量
HW=kron(ones(24,1),[1 0.1 0.07 0.006]);
% %首八(7)行为低八度的谐波信息
% %尾八(7)行为高八度的谐波信息
% HW=[1	0.265	0.050	0.0575%低八度
%     1	1.003	0.782	0.1025
%     1	0.255	0.156	0
%     1	0.255	0.156	0
%     1	0.4     0.1     0.145
%     1	1.208	0.208	0.1042
%     1	1.727	0.927	0.7583
%     0   0       0       0
%     1	0.265	0.050	0.0575%中频
%     1	0.423	0.127	0.0755
%     1	0.255	0.156	0
%     1	0.255	0.156	0
%     1	0.4     0.1     0.1450
%     1	1.208	0.208	0.1042
%     1	1.727	0.927	0.7583
%     0   0       0       0
%     1	0.265	0.050	0.0575%高八度
%     1	1.003	0.782	0.1025
%     1	0.255	0.156	0
%     1	0.255	0.156	0
%     1	0.4     0.1     0.145
%     1	1.208	0.208	0.1042
%     1	1.727	0.927	0.7583
%     0   0       0       0];
%<<<<<<<<-----------------------------------------------------------
%---该段代码实现以简谱数字为下标索引十二平均律的音调
%---其中3、4和7、i之间为半音，其余为全音
%---NMN：简谱(Numbered musical notation)
NMN=[0 2 4 5 7 9 11];
f=zeros(1,length(NMN));
for i=1:length(NMN)
    f(i)=f0*K^NMN(i);
end
f=[f,0];%数组的最后一个元素为f[8]=0，即中止符，
%----------------------------------------------------------->>>>>>>>

%<<<<<<<<-----------------------------------------------------------
%---该段代码用于翻译待播放音乐MtP
%---得到波形数组y，y可用sound函数直接播放，默认采样率8192Hz
y=[];
overlay=2000;%用于产生音符叠接，增强音符之间的连续性
for i=1:length(MtP(1,:))
    note_time=0:T:MtP(2,i)*0.5*pattime+overlay*T;%音符长度
    % MtP(2,i)个8分音符,另加overlay个T用于产生信号重叠效果
    
    t=2^MtP(3,i);%升调或降调八度
    %增加谐波信息
    Wave=sin(2*pi*f(MtP(1,i))*t*[1;2;3;4]*note_time);
    Wave=HW(MtP(1,i)+MtP(3,i)*8+8,:)*Wave;%各次谐波按各自幅值叠加
   
%<<<<<<<<-----------------------------------------------------------
%---三角波包络线
%    n=1:length(Wave);
%    envelope=tripuls(n-0.5*length(n),length(n));
%----------------------------------------------------------->>>>>>>>

%<<<<<<<<-----------------------------------------------------------
%---等腰梯形包络线，on=上底/下底，min=最小值，1=最大值
%    n=1:length(Wave);
%    on=0.9;
%    min=0.2;
%    envelope=min+(1-min)*((1/(1-on))*(tripuls(n-0.5*length(n),length(n))...
%        -tripuls(n-0.5*length(n),on*length(n))*on));
%___________________________________________________________>>>>>>>>

%<<<<<<<<-----------------------------------------------------------
%---钢琴音包络线x/exp(x)
    n=1:length(Wave);
    envelope=exp(1)*(10*n/length(n))./exp(10*n/length(n));
%----------------------------------------------------------->>>>>>>>
    Wave=Wave.*envelope;%给波形添加包络，以模拟乐器发声时由弱至强的效果

%<<<<<<<<-----------------------------------------------------------
%---串接一首歌中所有音符，相邻音符之间略有混叠，以模拟余音
  if i==1
      y=Wave;
  else
      part1=y(1:(length(y)-overlay));
      part2=y((length(y)-overlay+1):length(y))+Wave(1:overlay);
      part3=Wave(overlay+1:length(Wave));
      y=[part1 part2 part3];
  end
%----------------------------------------------------------->>>>>>>>
 
end
audiowrite('demo.wav',y,freq);%写音频文件
sound(y);%播放音乐
close all;
plot((1:length(y))/length(y)*500,y);%绘制整首歌的波形
figure;%另开一图
plot(Wave);%绘制最后一个音符的波形
play=length(y)/freq;
end


function Music_lib=M_library(i)
%---乐库
%---格式：每段音乐文件为一个3*n矩阵
%---第一行为简谱
%---第二行为持续时间(以八分音符为一个时间单位)
%---第三行为升降调，以一个八度为单位
%----------------------------------------
%---Unknow Music 未知音乐（PDF中示例曲段）
UM=[5 5 6 2 1 1 6 2
    2 1 1 4 2 1 1 4
    0 0 0 0 0 0 -1 0];
%-----------------------------------------
% ---Ode to joy 欢乐颂
OtJ=[3 3 4 5 5 4 3 2 1 1 2 3 3 2 2 3 3 4 5 5 4 3 2 1 1 2 3 2 1 1 ...
     2 2 3 1 2 3 4 3 1 2 3 4 3 2 1 2 5 3 3 4 5 5 4 3 2 1 1 2 3 2 1 1
     2 2 2 2 2 2 2 2 2 2 2 2 3 1 4 2 2 2 2 2 2 2 2 2 2 2 2 3 1 4 ...
     2 2 2 2 2 1 1 2 2 2 1 1 2 2 2 2 3 2 2 2 2 2 2 2 2 2 2 2 2 3 1 4
     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
%-----------------------------------------
%---City of Sky 天空之城
CoS=[  6 7 1 7 1 3 7 3 3 6 5 6 1 5 8 3 3 4 3 4 1 3 8 ...
       1 1 1 7 4 4 7 7 8 6 7 1 7 1 3 7 8 3 3 6 5 6 1 5 ...
       8 3 4 1 7 7 1 2 2 3 1 8 1 7 6 6 7 5 6 8 1 2 3 2 3 5 2 8 ...
       5 5 1 7 1 3 3 8 8 6 7 1 7 2 2 1 5 5 8 4 3 2 1 3 ...
       8 3 6 5 5 3 2 1 8 1 2 1 2 2 5 3 8 3 6 5 3 2 1 8 1 2 ...
       1 2 2 7 6 8 6 7 6
       1 1 3 1 1 2 6 1 1 3 1 2 2 4 2 1 1 3 1 1 3 4 2 ...
       1 1 1 3 1 2 2 4 2 1 1 3 1 2 2 4 2 1 1 3 1 2 2 6 ...
       1 1 2 1 1 2 2 1 1 1 2 2 2 1 1 1 2 2 4 2 1 1 3 1 2 2 4 2 ...
       1 1 1 1 2 2 4 2 2 1 1 2 2 1 1 3 1 2 2 2 2 2 2 12 ...
       2 2 4 2 2 1 1 2 1 1 2 1 1 1 2 4 2 2 4 4 1 1 4 1 1 2 ...
       1 1 1 2 4 2 1 1 4
       0 0 1 0 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 ...
       1 1 1 0 0 0 0 0 0 0 0 1 0 1 1 0 0 0 0 0 0 0 1 0 ...
       0 0 0 1 0 0 1 1 1 1 1 0 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 ...
       0 0 1 0 1 1 1 0 0 0 0 1 0 1 1 1 1 0 0 0 1 1 1 1 ...
       1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 ...
       1 1 1 0 0 0 0 0 0
       ];

    switch i
        case 1
            Music_lib=UM;
        case 2
            Music_lib=CoS;
        case 3
            Music_lib=OtJ;
        otherwise
            Music_lib=[];
    end
end
%------------------------------------------>>>>>>>>>>>>>>>>>>>>>>>>>