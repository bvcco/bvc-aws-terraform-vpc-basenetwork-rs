/*
  VPN configuration
*/
resource "aws_vpn_gateway" "vpn_gateway" {
  count  = var.build_vpn ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    "Name" : format("%s-VPNGateway", var.vpc_name)
    "transitvpc:spoke" : var.spoke_vpc
  }, local.base_tags, var.custom_tags)
}

resource "aws_vpn_gateway_route_propagation" "vpn_routes_public" {
  count          = var.build_vpn ? 1 : 0
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway[count.index].id
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_vpn_gateway_route_propagation" "vpn_routes_private" {
  count          = var.build_vpn ? length(var.private_cidr_ranges) : 0
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway[count.index].id
  route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
}
