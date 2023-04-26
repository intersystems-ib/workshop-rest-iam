Class Webinar.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Webinar.Production" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="GenericService" Category="" ClassName="EnsLib.REST.GenericService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigName">GenericOperation</Setting>
  </Item>
  <Item Name="GenericOperation" Category="" ClassName="EnsLib.REST.GenericOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="HTTPServer">httpbin.org</Setting>
    <Setting Target="Adapter" Name="URL">|</Setting>
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
  </Item>
</Production>
}

}
