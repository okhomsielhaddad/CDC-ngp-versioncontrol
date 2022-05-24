import { LightningElement, track } from 'lwc';
import doLogin from '@salesforce/apex/CommunityAuthController.doLogin';

export default class loginComponent extends LightningElement {
    username;
    password;
    @track errorCheck;
    @track errorMessage;

    connectedCallback(){
        console.log('test + ' + this.readCookie('theEmail'));
        this.template.querySelector('[data-id="inputUsername"]').value = this.readCookie('theEmail');
    }

    handleUserNameChange(event){
        this.username = event.target.value;
    }

    handlePasswordChange(event){
        this.password = event.target.value;
    }

    handleLogin(event){
        if(this.username && this.password){
            this.newCookie('theEmail', this.username);
            event.preventDefault();
            doLogin({ username: this.username, password: this.password })
                .then((result) => {
                    window.location.href = result;
                })
                .catch((error) => {
                    this.error = error;
                    this.errorCheck = true;
                    this.errorMessage = error.body.message;
                    console.log('Error Logging In '+this.errorMessage);
                });
        }
    }

    newCookie(name,value,days) {
        var days = 1;   // the number at the left reflects the number of days for the cookie to last
                        // modify it according to your needs
        if (days) {
          var date = new Date();
          date.setTime(date.getTime()+(days*24*60*60*1000));
          var expires = "; expires="+date.toGMTString();
          document.cookie = name+"="+value+expires+"; path=/";
        } else {
            document.cookie = name+"="+value+"; path=/";
        }
    }

    readCookie(name) {
        var nameSG = name + "=";
        var nuller = '';
        if (document.cookie.indexOf(nameSG) == -1)
        return nuller;

        var ca = document.cookie.split(';');
        for(var i=0; i<ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0)==' ') c = c.substring(1,c.length);
            if (c.indexOf(nameSG) == 0) return c.substring(nameSG.length,c.length);
        }
        return null;
    }

    eraseCookie(name) {
        this.newCookie(name,"",1);
    }
}