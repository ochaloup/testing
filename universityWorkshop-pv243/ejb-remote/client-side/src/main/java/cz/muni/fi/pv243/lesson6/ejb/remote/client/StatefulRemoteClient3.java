/*
 * JBoss, Home of Professional Open Source.
 * Copyright 2012, Red Hat, Inc., and individual contributors
 * as indicated by the @author tags. See the copyright.txt file in the
 * distribution for a full listing of individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

package cz.muni.fi.pv243.lesson6.ejb.remote.client;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import cz.muni.fi.pv243.lesson06.ejb.remote.stateful.StatefulRemote;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

/**
 * @author Ondrej Chaloupka
 */
public class StatefulRemoteClient3 {
	private static List<StatefulRemote> sbList = new ArrayList<StatefulRemote>();
	private static final int SLEEP_TIME_MS = 200;
	private static final int DEFAULT_NUM_OF_BEANS_TO_ADD = 50;
	
	public static void main(String[] args) throws Exception {
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
		System.out.println("To exit enter 'q', to add beans 'add <number>', to print ration 'ratio':");
		String input = "";
		
		while (!"q".equals(input) && !"quit".equals(input)) {
			System.out.print("$ ");
			input = br.readLine().trim();
			
			String[] splittedString = input.split(" ", 2);
			String param = splittedString.length > 1 ? splittedString[1] : null; 

			if(input.startsWith("add")) {
				Integer bbb = DEFAULT_NUM_OF_BEANS_TO_ADD;
				try {
					bbb = Integer.parseInt(param);
				} catch (Exception e) {
					// nothing interesting for us
				}
				System.out.println("Adding : " + bbb + " beans");
				addSBBeans(bbb);
			}
			
			if(input.startsWith("ratio") || input.startsWith("print")) {
				System.out.print("Info on ratio: ");
				printRatio();
			}
		}
		
		removeBeans();
	}

	/**
	 * Do remote lookup.
	 * 
	 * @see https ://docs.jboss.org/author/display/AS71/EJB+invocations+from+a+remote+client+using+JNDI
	 */
	private static StatefulRemote lookupStatefulRemote() throws NamingException {
		final Properties jndiProperties = new Properties();
		jndiProperties.put(Context.URL_PKG_PREFIXES,
				"org.jboss.ejb.client.naming");
		final Context ctx = new InitialContext(jndiProperties);

		StatefulRemote bean = (StatefulRemote) ctx
				.lookup("ejb:/lesson6-server-side-1.0.0-SNAPSHOT//StatefulBean!" + StatefulRemote.class.getName() + "?stateful");
		ctx.close();
		return bean;
	}

	private static void addSBBeans(int numberOfRuns) throws Exception {
		for(int i=0; i < numberOfRuns; i++) {
			StatefulRemote sb = lookupStatefulRemote();
			sb.addString(Integer.toString(i));
			System.out.println("Bean created on: " + sb.getNodeName());
			sbList.add(sb);
			Thread.sleep(SLEEP_TIME_MS);
		}
	}
	
	private static void printRatio() {
		Map<String, Integer> sbMap = new HashMap<String, Integer>();
		Integer total = 0;
		for(StatefulRemote sfsb: sbList) {
			String nodeName = sfsb.getNodeName();
			Integer number = sbMap.get(nodeName) == null ? 1 : sbMap.get(nodeName) + 1; 
			sbMap.put(nodeName, number);
			total++;
		}
		StringBuilder stringBuilder = new StringBuilder("");
		for(String nodeName: sbMap.keySet()) {
			stringBuilder.append(String.format("[%s: %1.2f %%]", nodeName, (sbMap.get(nodeName) * 1.0/total) * 100 ));
		}
		System.out.println(stringBuilder);
	}
	
	private static void removeBeans() {
		for(StatefulRemote sfsb: sbList) {
			sfsb.remove();
		}
	}
}
