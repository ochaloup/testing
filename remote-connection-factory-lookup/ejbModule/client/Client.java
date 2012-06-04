package client;

import javax.naming.InitialContext;

import bean.Bean;

public class Client {
	public static void main(String[] args) throws Exception {
		Bean bean = null;
		InitialContext ic = null;
		
		String lookup = "myejb/Bean!ochaloup.StatelessBeanRemote";
		if(args.length > 0 && args[0].trim().equals("1")) {
			ic = getOldSchoolIC(host, port);
			bean = (StatelessBeanRemote) ic.lookup(lookup);
		} else if(args.length > 0 && args[0].trim().equals("2")) {
			ic = getFancyNewIC(host, port);
			bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
		} else {
			ic = getFancyNewICNotRedefined();
			bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
		}

		System.out.println(bean.sayHello());
        ic.close();
	}
}
