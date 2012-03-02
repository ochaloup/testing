package org.jboss.as.test.multinode.transaction;

import java.rmi.RemoteException;

import javax.ejb.Remote;
import javax.naming.NamingException;
import javax.transaction.NotSupportedException;
import javax.transaction.SystemException;

@Remote
public interface ClientEjbRemote {
    void testSameTransactionEachCall() throws RemoteException, SystemException, NotSupportedException, NamingException;
}
