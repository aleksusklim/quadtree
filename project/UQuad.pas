
unit UQuad;

interface

uses StBase,StList,StColl;

type Datatype=Double;

const PageSize=1024;


type TQuad2=class;

TGrid2=class(TObject)
constructor Create(w:Integer);
destructor Destroy();override;
procedure Clear();
function Add(obj:Pointer;x1,y1,x2,y2:Datatype):TQuad2;
function Dump(q:Boolean=false):TStList;
function Get(x,y,w,h:Datatype):TStList;
private
w:Integer;
g:TStCollection;
end;

TQuad2=class(TObject)
constructor Create(x,y,w:Datatype;q:TQuad2=nil;g:TGrid2=nil);
destructor Destroy();override;
procedure Clear();
function Add(obj:Pointer;x1,y1,x2,y2:Datatype;t:Boolean=false;n:Boolean=false):TQuad2;
function Dump(r:TStList=nil;q:Boolean=false):TStList;
function Move(obj:Pointer;x1,y1,x2,y2:Datatype):TQuad2;
function Get(x,y,w,h:Datatype;r:TStList=nil):TStList;
function Del(obj:Pointer;t:TQuad2=nil):TQuad2;
private
a0,a1,b0,b1,c0,c1:Datatype;
q,q00,q01,q10,q11:TQuad2;
g:TGrid2;
ar:TStList;


end;


implementation

uses Math, SysUtils;

function floor(const v:Extended):Integer;overload;
begin
Result:=Math.Floor(v);
end;

function floor(const v:Integer):Integer;overload;
begin
Result:=v;
end;

function myhalf(const v:Extended):Extended;overload;
begin
Result:=v/2;
end;

function myhalf(const v:Integer):Integer;overload;
begin
Result:=v div 2;
end;

function mymod(const n,m:Integer):Integer;
begin
Result:=((n mod m)+m)mod m;
end;

function mydiv(const n:Datatype;const m:Integer):Integer;
begin
Result:=floor(n) div m;
end;

constructor TGrid2.Create(w:Integer);
begin
inherited Create();
Self.w:=w;
Self.g:=TStCollection.Create(PageSize);
end;

destructor TGrid2.Destroy();
begin
Clear();
Self.g.Free();
inherited Destroy();
end;

function TGrid2_Clear_2(Container : TStContainer;
 Data : Pointer;
 OtherData : Pointer) : Boolean;
begin
TQuad2(Data).Free();
end;

function TGrid2_Clear_1(Container : TStContainer;
 Data : Pointer;
 OtherData : Pointer) : Boolean;
begin
TStCollection(Container).Iterate(TGrid2_Clear_2,True,OtherData);
TStCollection(Container).Free();
end;

procedure TGrid2.Clear();
begin
self.g.Iterate(TGrid2_Clear_1,true,nil);
self.g.Clear();
end;

function TGrid2.Add(obj:Pointer;x1,y1,x2,y2:Datatype):TQuad2;
var w,x,y:Integer;
g,c:TStCollection;
begin
w:=Self.w;
g:=Self.g;
x:=mydiv(x1,w);
y:=mydiv(y1,w);
if g[x]=nil then g[x]:=TStCollection.Create(PageSize);
c:=g[x];
if c[y]=nil then c[y]:=TQuad2.Create(x*w,y*w,w,nil,Self);
Result:=TQuad2(c[y]).Add(obj,x1,y1,x2,y2,true);
end;

var iterate_q:Boolean;

function TGrid2_Dump_2(Container : TStContainer;
 Data : Pointer;
 OtherData : Pointer) : Boolean;
begin
TQuad2(Data).Dump(TStList(OtherData),iterate_q);
end;

function TGrid2_Dump_1(Container : TStContainer;
 Data : Pointer;
 OtherData : Pointer) : Boolean;
begin
TStCollection(Container).Iterate(TGrid2_Dump_2,True,OtherData);
end;

function TGrid2.Dump(q:Boolean=false):TStList;
begin
iterate_q:=q;
Result:=TStList.Create(TStListNode);
self.g.Iterate(TGrid2_Dump_1,true,Result);
end;

function TGrid2.Get(x,y,w,h:Datatype):TStList;
var s:Integer;
g,c:TStCollection;
q:TQuad2;
ii,xx,yy,ww,hh:Integer;
begin
Result:=TStList.Create(TStListNode);
s:=self.w;
g:=self.g;
xx:=mydiv(x,s)-1;
ii:=mydiv(y,s)-1;
ww:=mydiv(x+w,s);
hh:=mydiv(y+h,s);
repeat
c:=g[xx];
if c<>nil then begin
yy:=ii;
repeat
q:=c[yy];
if q<>nil then q.Get(x,y,w,h,Result);
Inc(yy);
until yy>hh;
end;
Inc(xx);
until xx>ww;
end;


constructor TQuad2.Create(x,y,w:Datatype;q:TQuad2=nil;g:TGrid2=nil);
begin
inherited Create();
Self.a0:=x;
Self.a1:=y;
Self.b0:=x+w;
Self.b1:=y+w;
w:=myhalf(w);
Self.c0:=x+w;
Self.c1:=y+w;
Self.q:=q;
if q<>nil then Self.g:=q.g else Self.g:=g;
end;

destructor TQuad2.Destroy();
begin
Clear();
inherited Destroy();
end;

procedure TQuad2.Clear();
begin
if self.ar<>nil then begin
self.ar.Clear();
FreeAndNil(self.ar);
end;
FreeAndNil(self.q00);
FreeAndNil(self.q01);
FreeAndNil(self.q10);
FreeAndNil(self.q11);
end;

function TQuad2.Add(obj:Pointer;x1,y1,x2,y2:Datatype;t:Boolean=false;n:Boolean=false):TQuad2;
begin
if(not t)and(g<>nil)and((mydiv(a0,g.w)<>mydiv(x1,g.w))or(mydiv(a1,g.w)<>mydiv(y1,g.w)))then begin
Result:=g.Add(obj,x1,y1,x2,y2);
Exit;
end;
if x1>=c0 then begin if x2<b0 then begin
if y1>=c1 then begin ify2<b1 then begin
if q11=nil then q11:=TQuad2.Create(c0,c1,c0-a0,this);
Result:=q11.Add(obj,x1,y1,x2,y2,true);
end end else if y2<c1 then begin if y1>=a1 begin 
if not this.q10)this.q10=new Quad2(c0,a1,c0-a0,this);
return this.q10.Add(obj,x1,y1,x2,y2,true);
}}}}else if(x2<c0){if(x1>=a0){
if(y1>=c1){if(y2<b1){
if(!this.q01)this.q01=new Quad2(a0,c1,c0-a0,this);
return this.q01.Add(obj,x1,y1,x2,y2,true);
}}else if(y2<c1){if(y1>=a1){
if(!this.q00)this.q00=new Quad2(a0,a1,c0-a0,this);
return this.q00.Add(obj,x1,y1,x2,y2,true);
}}}}
if(!t&&this.q)return this.q.Add(obj,x1,y1,x2,y2);
if(n)return null;
if(!this.ar)this.ar=[];
this.ar.push(obj);
return this;

end;

function TQuad2.Dump(r:TStList=nil;q:Boolean=false):TStList;
begin
end;

function TQuad2.Move(obj:Pointer;x1,y1,x2,y2:Datatype):TQuad2;
begin
Result:=self.Add(obj,x1,y1,x2,y2,false,true);
if Result<>nil then self.Del(obj)
else Result:=self;
end;

function TQuad2.Get(x,y,w,h:Datatype;r:TStList=nil):TStList;
begin
end;

function TQuad2.Del(obj:Pointer;t:TQuad2=nil):TQuad2;
begin

end;


end.
