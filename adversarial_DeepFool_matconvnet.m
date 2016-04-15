%%
%   MATLAB code for DeepFool
%
%   adversarial_DeepFool_matconvnet(x,net):
%   computes the adversarial perturbations for a MatConvNet's model
%
%   INPUTS
%   x: image in W*H*C format
%   net: MatConvNet's network (without loss layer)
%   opts: A struct contains parameters (see README)
%   OUTPUTS
%   r_hat: minimum perturbation
%   l_hat: adversarial label
%   l: classified label
%   itr: number of iterations
%
%   please cite: S. Moosavi-Dezfooli, A. Fawzi, P. Frossard: DeepFool: a simple and accurate method to fool deep neural networks.
%                In Computer Vision and Pattern Recognition (CVPR ’16), IEEE, 2016.
%%
function [r_hat,l_hat,l,itr] = adversarial_DeepFool_matconvnet(x,net,opts)
size_x = size(x);
c = numel(net.layers{end}.weights{2});

x = reshape(x,numel(x),1);
l=f(x,1);

if(nargin==3)
    adv = adversarial_perturbation(x,l,@Df,@f,opts);
else
    adv = adversarial_perturbation(x,l,@Df,@f);
end

l_hat = adv.new_label;
r_hat = reshape(adv.r,size_x);
itr = adv.itr;

    function out = f(y,flag)
        for i=1:c
            %do forward pass
            res = vl_simplenn(net,single(reshape(y,size_x)),[],[],'Mode','test');
            out(i) = res(end).x(i);
        end
        
        %flag==0:compute the outputs
        %flag==1:compute the label
        if flag==1
            [~,out] = max(out);
        end
    end

    function dzdx = Df(y,label,idx)
        for i=1:numel(idx)
            
            dzdy = zeros(1,1,c,'single');
            dzdy(idx(i)) = 1;
            
            %do forward-backward pass
            res = vl_simplenn(net,single(reshape(y,size_x)),dzdy,[],'Mode','test');
            dzdx(:,i) = reshape(res(1).dzdx,prod(size_x),1);
        end
        dzdx = dzdx-repmat(dzdx(:,idx==label),1,numel(idx));
    end

end