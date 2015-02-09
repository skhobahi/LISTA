local NormSpatialConvolutionMM, parent = torch.class('nn.NormSpatialConvolutionMM', 'nn.Module')

function NormSpatialConvolutionMM:__init(nInputPlane, nOutputPlane, kW, kH, dW, dH, padding)
   parent.__init(self)
   
   dW = dW or 1
   dH = dH or 1

   self.nInputPlane = nInputPlane
   self.nOutputPlane = nOutputPlane
   self.kW = kW
   self.kH = kH

   self.dW = dW
   self.dH = dH
   self.padding = padding or 0

   self.weight = torch.Tensor(nOutputPlane, nInputPlane*kH*kW)
   self.bias = torch.Tensor(nOutputPlane)
   self.gradWeight = torch.Tensor(nOutputPlane, nInputPlane*kH*kW)
   self.gradBias = torch.Tensor(nOutputPlane)

   self.finput = torch.Tensor()
   self.fgradInput = torch.Tensor()
   
   self:reset()
end

function NormSpatialConvolutionMM:norm_filters() 
    local w = self.weight
    local norm = w:norm(2,2):expandAs(w):contiguous() 
    w:cdiv(norm)
    collectgarbage() 
end

function NormSpatialConvolutionMM:reset(stdv)
   if stdv then
      stdv = stdv * math.sqrt(3)
   else
      stdv = 1/math.sqrt(self.kW*self.kH*self.nInputPlane)
   end
   if nn.oldSeed then
      self.weight:apply(function()
         return torch.uniform(-stdv, stdv)
      end)
      self.bias:apply(function()
         return torch.uniform(-stdv, stdv)
      end)  
   else
      self.weight:uniform(-stdv, stdv)
      self.bias:uniform(-stdv, stdv)
   end
end

local function makeContiguous(self, input, gradOutput)
   if not input:isContiguous() then
      self._input = self._input or input.new()
      self._input:resizeAs(input):copy(input)
      input = self._input
   end
   if gradOutput then
      if not gradOutput:isContiguous() then
     self._gradOutput = self._gradOutput or gradOutput.new()
     self._gradOutput:resizeAs(gradOutput):copy(gradOutput)
     gradOutput = self._gradOutput
      end
   end
   return input, gradOutput
end

function NormSpatialConvolutionMM:updateOutput(input)
   input = makeContiguous(self, input)
   self:norm_filters()  
   return input.nn.SpatialConvolutionMM_updateOutput(self, input)
end

function NormSpatialConvolutionMM:updateGradInput(input, gradOutput)
   if self.gradInput then
      input, gradOutput = makeContiguous(self, input, gradOutput)
      return input.nn.SpatialConvolutionMM_updateGradInput(self, input, gradOutput)
   end
end

function NormSpatialConvolutionMM:accGradParameters(input, gradOutput, scale)
   input, gradOutput = makeContiguous(self, input, gradOutput)
   return input.nn.SpatialConvolutionMM_accGradParameters(self, input, gradOutput, scale)
end
