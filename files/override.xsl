<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/domain/devices/rng[@model='virtio']/backend">
    <backend model='random'>/dev/random</backend>
  </xsl:template>

  <xsl:template match="/domain/devices/interface/source">
    <source network='${network}' portgroup='${port_group}'/>
  </xsl:template>

</xsl:stylesheet>
