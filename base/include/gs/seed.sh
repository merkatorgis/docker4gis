$(gs.sh POST gwc)/seed/$1.xml -d "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<seedRequest>
  <bounds>
    <coords>
      <double>$2</double>
      <double>$3</double>
      <double>$4</double>
      <double>$5</double>
    </coords>
  </bounds>
  <zoomStart>${6}</zoomStart>
  <zoomStop>${7}</zoomStop>
  <type>${8:-seed}</type>
  <threadCount>${9:-1}</threadCount>
</seedRequest>"
