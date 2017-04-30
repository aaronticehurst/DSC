@{
    AllNodes = @(
       @{
            Nodename = "test6"
            Role = "Primary DC"
            IPAddress = "10.1.1.204"
            DNSAddress = "10.1.1.204", "10.1.1.205"
            
        },

        @{
            Nodename = "Test7"
            Role = "Replica DC"            
            IPAddress = "10.1.1.205"
            DNSAddress = "10.1.1.204", "10.1.1.205"
        },

        @{
            Nodename = "Test3"
            Role = "Member"            
            IPAddress = "10.1.1.202"
            DNSAddress = "10.1.1.204"
        }
	 
    )

    DomainData = @(

        @{
            DomainName = "test.local"
            LocalAdministrator = "Administrator"
        }
    )
}