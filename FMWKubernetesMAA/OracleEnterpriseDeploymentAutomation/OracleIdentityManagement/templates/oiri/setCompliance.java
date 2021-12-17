/*
 *  Copyright (c) 2021, Oracle and/or its affiliates.
 *  Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 *  
 * This is an example of a Java script to set OIG Compliance Mode
 * 
 */
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class setCompliance {
   
   static final String baseURL = "jdbc:oracle:thin:@//";
   static final String USER = "idg_oim";
   static final String PASS = "Welcome1_01";
   static final String QUERY = "SELECT pty_keyword, pty_value from  pty where pty_keyword='OIG.IsIdentityAuditorEnabled'";
   static final String UPDATEPARAM = "update pty set pty_value='TRUE' where pty_keyword='OIG.IsIdentityAuditorEnabled'";

   static public void main(String[] args) {      
                String dbURL = args[0];
                String userName = args[1];
                String passwd = args[2];

   try {
         System.out.println("Server URL is : " + baseURL+dbURL);
         Connection conn = DriverManager.getConnection(baseURL+dbURL, userName, passwd);
         Statement stmt = conn.createStatement();

         stmt.executeUpdate(UPDATEPARAM);
         ResultSet rs = stmt.executeQuery(QUERY);

         while(rs.next()){
             System.out.print("keyword: " + rs.getString("pty_keyword"));
             System.out.println(" value: " + rs.getString("pty_value"));
         }
         rs.close();
      } catch (SQLException e) {
         e.printStackTrace();
      } 
   }
}

